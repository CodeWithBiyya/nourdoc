import 'package:flutter/material.dart';
import 'package:medicalai/utils/colors.dart';
import '../../routes/routs_name.dart';

class BottomLoginWidget extends StatelessWidget {
  // 1. Add variables to accept logic from the parent screen
  final VoidCallback? onHomeTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onEditTap;
  final bool isDeleteMode; // To toggle the edit icon/color

  const BottomLoginWidget({
    super.key,
    this.onHomeTap,
    this.onAddTap,
    this.onEditTap,
    this.isDeleteMode = false, // Default is false (Normal mode)
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 70,
          child: Stack(
            clipBehavior: Clip.none, // Allows the button to float out
            alignment: Alignment.bottomCenter,
            children: [
              // Background Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                height: 60,
                decoration: BoxDecoration(
                  color: Colorprimary,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // HOME BUTTON
                      IconButton(
                        onPressed: onHomeTap, // Calls the parent's function
                        icon: const Icon(
                            Icons.home,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            size: 30
                        ),
                      ),

                      const SizedBox(width: 60), // Gap for the center button

                      // EDIT BUTTON
                      IconButton(
                        // onPressed: onEditTap,
                        onPressed: null, // Disabled, can't be clicked, as for now we dont have the delete session in the backend.

                        // Changes icon based on mode
                        icon: Icon(
                            isDeleteMode ? Icons.close : Icons.edit,
                            // Changes color based on mode (Red when active)
                            color: isDeleteMode ? Colors.redAccent : Colors.white,
                            fontWeight: FontWeight.w900,
                            size: 30
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Center Button (Your Design)
              Positioned(
                top: -10, // Adjust this if needed to match your screenshot exactly
                child: GestureDetector(
                  onTap: onAddTap, // Calls the parent's function
                  child: Container(
                    height: 80,
                    width: 86,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colorprimary, width: 8),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 50,
                      color: Colorprimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




