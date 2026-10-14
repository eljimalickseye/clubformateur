<?php

namespace Tests\Feature;

use App\Models\LiveSession;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LiveAndGroupsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config([
            'services.livekit.url' => 'wss://live.test',
            'services.livekit.key' => 'cle-test',
            'services.livekit.secret' => 'secret-test-assez-long-pour-hs256-0123456789',
        ]);
    }

    private function makeUser(string $uid, string $role): User
    {
        return User::create([
            'uid' => $uid,
            'name' => $uid,
            'email' => $uid . '@example.com',
            'password' => 'motdepasse-solide',
            'role' => $role,
            'api_token' => 'token-' . $uid,
        ]);
    }

    private function claims(string $jwt): array
    {
        $payload = explode('.', $jwt)[1];

        return json_decode(base64_decode(strtr($payload, '-_', '+/')), true);
    }

    public function test_student_cannot_start_a_live_session(): void
    {
        $this->makeUser('eleve', 'student');

        $this->withToken('token-eleve')
            ->postJson('/api/v1/live-sessions', ['courseId' => 'c1', 'title' => 'Live'])
            ->assertStatus(403);
    }

    public function test_only_the_host_gets_publish_rights_and_the_client_cannot_ask_for_them(): void
    {
        $this->makeUser('prof', 'teacher');
        $this->makeUser('eleve', 'student');

        $created = $this->withToken('token-prof')
            ->postJson('/api/v1/live-sessions', ['courseId' => 'c1', 'title' => 'Live'])
            ->assertCreated();
        $room = $created->json('livekit.roomName');
        $this->assertTrue($this->claims($created->json('livekit.token'))['video']['canPublish']);

        $token = $this->withToken('token-eleve')
            ->postJson('/api/v1/livekit/token', ['roomName' => $room, 'isTeacher' => true])
            ->assertOk()
            ->json('token');

        $claims = $this->claims($token);
        $this->assertFalse($claims['video']['canPublish']);
        $this->assertSame('eleve', $claims['sub']);
    }

    public function test_token_is_refused_for_an_unknown_room(): void
    {
        $this->makeUser('eleve', 'student');

        $this->withToken('token-eleve')
            ->postJson('/api/v1/livekit/token', ['roomName' => 'salle-inexistante'])
            ->assertStatus(404);
    }

    public function test_only_the_host_can_end_the_session(): void
    {
        $this->makeUser('prof', 'teacher');
        $this->makeUser('rival', 'teacher');
        $this->withToken('token-prof')->postJson('/api/v1/live-sessions', ['courseId' => 'c1', 'title' => 'Live']);
        $id = LiveSession::first()->session_uid;

        $this->withToken('token-rival')->postJson("/api/v1/live-sessions/$id/end")->assertStatus(403);
        $this->withToken('token-prof')->postJson("/api/v1/live-sessions/$id/end")->assertOk();
        $this->assertSame('ended', LiveSession::first()->status);
    }

    public function test_study_group_messages_are_limited_to_members(): void
    {
        $this->makeUser('eleve', 'student');
        $this->makeUser('intrus', 'student');

        $this->withToken('token-eleve')->postJson('/api/v1/study-groups', ['name' => 'Revisions'])->assertCreated();
        $groupId = \App\Models\StudyGroup::first()->group_uid;

        $this->withToken('token-eleve')
            ->postJson("/api/v1/study-groups/$groupId/messages", ['content' => 'Salut', 'senderId' => 'autre'])
            ->assertCreated();
        $this->withToken('token-intrus')->getJson("/api/v1/study-groups/$groupId/messages")->assertStatus(403);
        $this->withToken('token-intrus')
            ->postJson("/api/v1/study-groups/$groupId/messages", ['content' => 'Spam'])
            ->assertStatus(403);

        $this->withToken('token-intrus')->postJson("/api/v1/study-groups/$groupId/join")->assertOk();
        $this->withToken('token-intrus')->getJson("/api/v1/study-groups/$groupId/messages")->assertOk();
    }
}
