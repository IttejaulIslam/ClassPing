/// East Delta University — B.Sc. in Computer Science & Engineering (CSE)
/// Full Course Catalog (166 total credits, 9 semesters)
/// Transcribed from the official EDU CSE brochure (course catalog pages).
/// Source catalog last updated 21 April 2024 (per brochure back page).
///
/// Used by the GPA/CGPA calculator's course-name autocomplete so students
/// pick a course (by name or code) instead of typing it from scratch.
library;

class CatalogCourse {
  final String code;
  final String title;
  final double credit;
  final String category;

  const CatalogCourse({
    required this.code,
    required this.title,
    required this.credit,
    required this.category,
  });

  String get displayLabel => '$code \u2014 $title';
}

const List<CatalogCourse> accessAcademyCourses = [
  CatalogCourse(code: 'AA099', title: 'Academic Reading and Writing', credit: 0, category: 'Access Academy'),
  CatalogCourse(code: 'AA150', title: 'Fundamentals of Quantitative Reasoning', credit: 0, category: 'Access Academy'),
  CatalogCourse(code: 'AA200', title: 'Student Development Seminars', credit: 0, category: 'Access Academy'),
];

const List<CatalogCourse> languageSkillCourses = [
  CatalogCourse(code: 'ENG111', title: 'Advanced Academic Reading & Writing', credit: 3, category: 'Language Skill'),
  CatalogCourse(code: 'ENG112', title: 'Advanced Academic Listening & Speaking', credit: 1.5, category: 'Language Skill'),
];

/// University Program (UP) — student selects courses totaling 12 credits.
const List<CatalogCourse> universityProgramCourses = [
  CatalogCourse(code: 'BNG101', title: 'Bangla Language and Literature', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'HIS101', title: 'History of the Emergence of Bangladesh', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'PSC100', title: 'Introduction to Political Science', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'IGLE300', title: 'International Graduate Leadership Experience', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'SOC101', title: 'Introduction to Sociology', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'JRN101', title: 'Mass Communication in Contemporary Society', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'BCH101', title: 'Bangladesh Culture and Heritage', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'BPH101', title: 'Bangladesh Political History', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'PSY101', title: 'Principles of Psychology', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'ANT101', title: 'Physical Anthropology', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'FRN101', title: 'Elementary French I', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'SDA101', title: 'Public Speaking', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'PHI102', title: 'Moral Problems', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'PSC150', title: 'World Politics', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'ECO203', title: 'Bangladesh Economy', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'ENG300', title: 'Critical Reading and Writing Skills', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'IGS101', title: "Introduction to Gender and Women's Studies", credit: 3, category: 'University Program'),
  CatalogCourse(code: 'IIR101', title: 'Introduction to International Relations Theory', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'WPP101', title: 'Western Political Philosophy', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'BUS300', title: 'Business Communication', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'HUM105', title: 'Bangladesh Studies', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'HUM107', title: 'Industrial Management and Law', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'HUM201', title: 'Macro & Microeconomics', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'HUM203', title: 'Communication Skills for Engineers', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'HUM211', title: 'Entrepreneurship for Engineers', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'HUM301', title: 'Financial & Managerial Accounting', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'HUM303', title: 'Sociology & Ethics', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'HUM305', title: 'Professional Ethics & Environmental Protection', credit: 3, category: 'University Program'),
  CatalogCourse(code: 'IPD400', title: 'Integrated Professional Development', credit: 3, category: 'University Program'),
];

/// Interdisciplinary Courses (CSE track) — 10.5 credits total.
const List<CatalogCourse> interdisciplinaryCourses = [
  CatalogCourse(code: 'ME102', title: 'Engineering Drawing', credit: 1.5, category: 'Interdisciplinary'),
  CatalogCourse(code: 'EEE111', title: 'Introduction to Electrical Engineering', credit: 3, category: 'Interdisciplinary'),
  CatalogCourse(code: 'EEE112', title: 'Introduction to Electrical Engineering Laboratory', credit: 1.5, category: 'Interdisciplinary'),
  CatalogCourse(code: 'CSE223', title: 'Digital Electronics & Pulse Technique', credit: 3, category: 'Interdisciplinary'),
  CatalogCourse(code: 'CSE224', title: 'Digital Electronics & Pulse Technique Laboratory', credit: 1.5, category: 'Interdisciplinary'),
];

/// Basic Science Courses — 7.5 credits total.
const List<CatalogCourse> basicScienceCourses = [
  CatalogCourse(code: 'PHY101', title: 'Physics', credit: 3, category: 'Basic Science'),
  CatalogCourse(code: 'PHY102', title: 'Physics Laboratory', credit: 1.5, category: 'Basic Science'),
  CatalogCourse(code: 'CHEM201', title: 'Chemistry', credit: 3, category: 'Basic Science'),
];

/// Mathematics Courses (CSE track) — 15 credits total.
const List<CatalogCourse> mathematicsCourses = [
  CatalogCourse(code: 'MATH107', title: 'Math I \u2013 Differential Calculus, Co-ordinate Geometry & Complex Variables', credit: 3, category: 'Mathematics'),
  CatalogCourse(code: 'MATH203', title: 'Math IV \u2013 Fourier Analysis, Differential Equations & Laplace Transforms', credit: 3, category: 'Mathematics'),
  CatalogCourse(code: 'MATH207', title: 'Math II \u2013 Integral Calculus, Vector Analysis & Linear Algebra', credit: 3, category: 'Mathematics'),
  CatalogCourse(code: 'MATH205', title: 'Math III \u2013 Numerical Analysis', credit: 3, category: 'Mathematics'),
  CatalogCourse(code: 'MATH301', title: 'Math V \u2013 Probability & Statistics', credit: 3, category: 'Mathematics'),
];

/// Program Core Courses — 89.5 credits total.
const List<CatalogCourse> programCoreCourses = [
  CatalogCourse(code: 'CSE111', title: 'Computer Fundamentals and Programming Basics', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE112', title: 'Computer Fundamentals and Programming Basics Laboratory', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE113', title: 'Structured Programming Language', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE114', title: 'Structured Programming Language Laboratory', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE123', title: 'Object Oriented Programming Language', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE124', title: 'Object Oriented Programming Language Laboratory', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE115', title: 'Discrete Mathematics', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE211', title: 'Data Structure', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE212', title: 'Data Structure Laboratory', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE215', title: 'Digital Logic Design', credit: 4, category: 'Program Core'),
  CatalogCourse(code: 'CSE216', title: 'Digital Logic Design Laboratory', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE221', title: 'Algorithms', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE222', title: 'Algorithms Laboratory', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE225', title: 'Database Management System', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE226', title: 'Database Management System Laboratory', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE242', title: 'Web Development', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE311', title: 'Operating System', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE312', title: 'Operating System Laboratory', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE313', title: 'Data Communication', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE315', title: 'Microprocessor and Interfacing', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE316', title: 'Microprocessor & Interfacing Laboratory', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE317', title: 'Computer Organization and Architecture', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE319', title: 'Compiler Design', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE320', title: 'Compiler Design Lab', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE321', title: 'Computer Graphics', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE322', title: 'Computer Graphics Lab', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE325', title: 'Computer Networks', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE326', title: 'Computer Networks Laboratory', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE327', title: 'Artificial Intelligence', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE328', title: 'Artificial Intelligence Lab', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE342', title: 'IoT Based Project Development', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE466', title: 'Mobile App Development', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE411', title: 'Software Engineering', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE443', title: 'Neural Network and Fuzzy Systems', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE463', title: 'Machine Learning for Big Data Analytics', credit: 3, category: 'Program Core'),
  CatalogCourse(code: 'CSE464', title: 'Python Based Project Development', credit: 1.5, category: 'Program Core'),
  CatalogCourse(code: 'CSE400', title: 'Project/Thesis', credit: 6, category: 'Program Core'),
];

/// Options / Electives — 18 credits total (student picks a subset).
const List<CatalogCourse> electiveOptionCourses = [
  CatalogCourse(code: 'CSE301', title: 'Data Warehousing and Mining', credit: 3, category: 'Options'),
  CatalogCourse(code: 'CSE303', title: 'Introduction to Bioinformatics', credit: 3, category: 'Options'),
  CatalogCourse(code: 'CSE307', title: 'Mobile Computing and Applications', credit: 3, category: 'Options'),
  CatalogCourse(code: 'CSE308', title: 'Mobile Computing and Applications Lab', credit: 1.5, category: 'Options'),
  CatalogCourse(code: 'CSE309', title: 'Distributed Systems', credit: 3, category: 'Options'),
  CatalogCourse(code: 'CSE337', title: 'Multimedia Theory', credit: 3, category: 'Options'),
  CatalogCourse(code: 'CSE429', title: 'Software Project Management', credit: 3, category: 'Options'),
  CatalogCourse(code: 'CSE435', title: 'Pattern Recognition', credit: 3, category: 'Options'),
  CatalogCourse(code: 'CSE436', title: 'Pattern Recognition Lab', credit: 1.5, category: 'Options'),
  CatalogCourse(code: 'CSE439', title: 'Digital Image Processing', credit: 3, category: 'Options'),
  CatalogCourse(code: 'CSE440', title: 'Digital Image Processing Lab', credit: 1.5, category: 'Options'),
  CatalogCourse(code: 'CSE447', title: 'Robotics', credit: 3, category: 'Options'),
  CatalogCourse(code: 'CSE455', title: 'Business Process Reengineering', credit: 3, category: 'Options'),
  CatalogCourse(code: 'ETE309', title: 'Digital Signal Processing', credit: 3, category: 'Options'),
  CatalogCourse(code: 'ETE310', title: 'Digital Signal Processing Laboratory', credit: 1.5, category: 'Options'),
  CatalogCourse(code: 'ETE431', title: 'Mobile Cellular & Wireless Communication', credit: 3, category: 'Options'),
  CatalogCourse(code: 'ETE435', title: 'Digital Communication', credit: 3, category: 'Options'),
  CatalogCourse(code: 'ETE436', title: 'Digital Communication Laboratory', credit: 1.5, category: 'Options'),
  CatalogCourse(code: 'EEE213', title: 'Electronics Devices & Circuits', credit: 3, category: 'Options'),
  CatalogCourse(code: 'EEE214', title: 'Electronics Devices & Circuits Lab', credit: 1.5, category: 'Options'),
  CatalogCourse(code: 'EEE317', title: 'Electrical Drives & Instrumentation', credit: 3, category: 'Options'),
  CatalogCourse(code: 'EEE318', title: 'Electrical Drives & Instrumentation Lab', credit: 1.5, category: 'Options'),
  CatalogCourse(code: 'CSE457', title: 'Cyber Security', credit: 3, category: 'Options'),
  CatalogCourse(code: 'CSE459', title: 'Network Security', credit: 3, category: 'Options'),
];

/// Combined flat list — used for search/autocomplete in the course picker.
final List<CatalogCourse> allCseCourses = [
  ...accessAcademyCourses,
  ...languageSkillCourses,
  ...universityProgramCourses,
  ...interdisciplinaryCourses,
  ...basicScienceCourses,
  ...mathematicsCourses,
  ...programCoreCourses,
  ...electiveOptionCourses,
];

/// Quick lookup by course code, e.g. courseByCode['CSE225'].
final Map<String, CatalogCourse> courseByCode = {
  for (final c in allCseCourses) c.code: c,
};
