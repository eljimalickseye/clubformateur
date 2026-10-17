class TestimonialModel {
  final String id;
  final String authorName;
  final String authorRole;
  final String quote;
  final double rating;
  final String avatarUrl;

  TestimonialModel({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.quote,
    this.rating = 5.0,
    required this.avatarUrl,
  });

  static List<TestimonialModel> get defaultTestimonials => [
    TestimonialModel(
      id: '1',
      authorName: 'Ousmane Diallo',
      authorRole: 'Apprenant',
      quote: "Grâce à Club des Formateurs, j'ai pu acquérir de nouvelles compétences qui m'ont permis d'évoluer dans ma carrière. Une plateforme vraiment top !",
      rating: 5.0,
      avatarUrl: 'assets/images/student-man.jpeg',
    ),
    TestimonialModel(
      id: '2',
      authorName: 'Sophie Ndao',
      authorRole: 'Formatrice',
      quote: "En tant que formatrice, j'ai trouvé une communauté sérieuse et engagée. L'accompagnement est excellent.",
      rating: 5.0,
      avatarUrl: 'assets/images/student-woman.jpeg',
    ),
    TestimonialModel(
      id: '3',
      authorName: 'Ibrahima Kane',
      authorRole: 'Apprenant',
      quote: "Des formations de qualité, un contenu très pratique et des formateurs à l'écoute. Je recommande vivement !",
      rating: 5.0,
      avatarUrl: 'assets/images/student-school.jpeg',
    ),
  ];
}
