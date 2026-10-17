
const fs = require('fs');
const files = [
  'lib/screens/dashboards/teacher_dashboard_screen.dart',
  'lib/screens/dashboards/student_dashboard_screen.dart',
  'lib/screens/dashboards/corrector_dashboard_screen.dart',
  'lib/screens/dashboards/super_admin_dashboard_screen.dart'
];
for (const f of files) {
  let content = fs.readFileSync(f, 'utf8');
  if (!content.includes('marketing_section_header.dart')) {
    content = content.replace(/import [^\n]+;\n/, match => match + "import '../../widgets/marketing_section_header.dart';\n");
    fs.writeFileSync(f, content);
    console.log('Added to ' + f);
  }
}

