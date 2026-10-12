import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FormateurProfileComponent } from './formateur-profile.component';

describe('FormateurProfileComponent', () => {
  let component: FormateurProfileComponent;
  let fixture: ComponentFixture<FormateurProfileComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [FormateurProfileComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(FormateurProfileComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
