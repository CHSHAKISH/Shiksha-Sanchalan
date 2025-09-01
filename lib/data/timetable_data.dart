// A static class to hold all the data for the timetable.
class TimetableData {
  // A map where the key is the semester number and the value is a list of branches.
  static const Map<int, List<Map<String, dynamic>>> semesters = {
    1: [
      {'name': 'Computer Science', 'subjects': ['Maths-1', 'Physics', 'C Programming', 'BEE']},
      {'name': 'Mechanical', 'subjects': ['Maths-1', 'Physics', 'Mechanics', 'Graphics']},
      {'name': 'Civil', 'subjects': ['Maths-1', 'Physics', 'Geology', 'Surveying']},
      {'name': 'IT', 'subjects': ['Maths-1', 'Physics', 'Geology', 'Surveying']},
      // Add other branches for Semester 1
    ],
    2: [
      {'name': 'Computer Science', 'subjects': ['Maths-2', 'Chemistry', 'Data Structures', 'OOPs']},
      {'name': 'Mechanical', 'subjects': ['Maths-2', 'Chemistry', 'Thermodynamics', 'SOM']},
      {'name': 'Civil', 'subjects': ['Maths-2', 'Chemistry', 'Fluid Mechanics', 'MOS']},
      // Add other branches for Semester 2
    ],
    // Define subjects for Semesters 3 through 8 similarly...
    3: [
      {'name': 'Computer Science', 'subjects': ['Discrete Maths', 'DBMS', 'OS', 'COA']},
    ],
    4: [
      {'name': 'Computer Science', 'subjects': ['Algorithms', 'TOC', 'Compiler Design', 'SE']},
    ],
    5: [
      {'name': 'Computer Science', 'subjects': ['Networks', 'AI', 'Web Tech', 'Project-1']},
    ],
    6: [
      {'name': 'Computer Science', 'subjects': ['ML', 'Cryptography', 'Distributed Systems', 'Elective-1']},
    ],
    7: [
      {'name': 'Computer Science', 'subjects': ['Cloud Computing', 'Big Data', 'Elective-2', 'Project-2']},
    ],
    8: [
      {'name': 'Computer Science', 'subjects': ['Internship', 'Seminar']},
    ],
  };
}
