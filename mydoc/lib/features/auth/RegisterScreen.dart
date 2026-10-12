import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _RegisterScreen();
  }


}

class _RegisterScreen extends State {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  TextEditingController nameController =
  TextEditingController(text: "Dr. Ali Khan");
  TextEditingController emailController =
  TextEditingController(text: "alixxxx@gmail.com");
  TextEditingController mobileController = TextEditingController();

  String? specialty;
  String? experience;
  String? city;
  TextEditingController licenseController = TextEditingController();

  // Dropdown options
  final specialties = ["Cardiology", "Dermatology", "Neurology", "Orthopedics"];
  final experiences = ["1-3 years", "4-6 years", "7-10 years", "10+ years"];
  final cities = ["Karachi", "Lahore", "Islamabad", "Peshawar"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Doctor Profile",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text("Profile 25% Complete",
                          style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 20),
                    ],
                  ),
                ),

                // Name
                Text("Name: *", style: TextStyle(fontWeight: FontWeight.w500)),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.edit, size: 20),
                  ),
                ),
                SizedBox(height: 15),

                // Email
                Text("Email: *", style: TextStyle(fontWeight: FontWeight.w500)),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.edit, size: 20),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 15),

                // Mobile
                Text("Mobile No.: *",
                    style: TextStyle(fontWeight: FontWeight.w500)),
                TextFormField(
                  controller: mobileController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.whatshot, color: Colors.green),
                    hintText: "+92 xxx-xxx-xxxx",
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 15),

                // Specialty
                DropdownButtonFormField<String>(
                  value: specialty,
                  items: specialties
                      .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setState(() => specialty = value),
                  decoration: InputDecoration(labelText: "Specialty"),
                ),
                SizedBox(height: 15),

                // Experience
                DropdownButtonFormField<String>(
                  value: experience,
                  items: experiences
                      .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => experience = value),
                  decoration: InputDecoration(labelText: "Experience"),
                ),
                SizedBox(height: 15),

                // City
                DropdownButtonFormField<String>(
                  value: city,
                  items: cities
                      .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setState(() => city = value),
                  decoration: InputDecoration(labelText: "City"),
                ),
                SizedBox(height: 15),

                // License
                Text("PM & DC License No.:",
                    style: TextStyle(fontWeight: FontWeight.w500)),
                TextFormField(
                  controller: licenseController,
                  decoration: InputDecoration(
                      hintText: "e.g. 12345-N/M/YYYY"),
                ),
                SizedBox(height: 25),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Submit action
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: Text("Submit"),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: Text("Skip for now"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}