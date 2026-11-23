// ============================================================
//  Attendance System — settings and batch data
//  Change only this file when batches / students change.
// ============================================================

window.APP_CONFIG = {
  instituteName: "VigyanPath Classes",

  // Supabase (leave empty to run in offline/demo mode — data then stays
  // only on that one device). Fill these after running supabase.sql.
  supabaseUrl: "",
  supabaseAnonKey: "",
};

// Subjects shown in the Subject dropdown
window.SUBJECTS = ["Mathematics", "Physics", "Chemistry", "Biology"];

// Class → Batch → list of student names
// (sample names — replace with the real lists)
window.BATCHES = {
  "Class 12th": {
    "Fighter": [
      "Sachin Gurjar", "Aarav Sharma", "Ananya Verma", "Rohit Yadav",
      "Priya Singh", "Karan Tomar", "Sneha Jain", "Aditya Kushwah",
    ],
    "12th JEE": [
      "Vivek Rajput", "Neha Gupta", "Harsh Bhadoria", "Ishita Agrawal",
    ],
  },
  "Class 11th": {
    "Target JEE Main 2027": [
      "Rahul Mishra", "Pooja Rathore", "Ankit Sikarwar", "Divya Shrivastava",
    ],
  },
};
