import 'dart:io';

import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  TimeOfDay? chosenTime;
  String type = "lost";
  final titleField = TextEditingController();
  final descriptionField = TextEditingController();
  final locationField = TextEditingController();
  final timeController = TextEditingController(
    text: "Pick the approximate time when you lost it",
  );
  final picker = ImagePicker();
  XFile? pickedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Qstext("Create Lost or Found Entry")),
      body: SafeArea(
        child: BlocConsumer<CmBloc, CmState>(
          listenWhen: (previous, current) =>
              current is PostFailedState || current is PostSuccessState,
          listener: (context, state) {
            if (state is PostFailedState) {
              FocusManager.instance.primaryFocus?.unfocus();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Qstext(state.msg)));
            } else if (state is PostSuccessState) {
              Navigator.pop(context);
              context.read<CmBloc>().add(LoadItemsEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Qstext("Post Added Successfully"),
                  onVisible: () => Future.delayed(
                    Duration(seconds: 4),
                    ScaffoldMessenger.of(context).clearSnackBars,
                  ),
                  action: SnackBarAction(
                    label: "OK",
                    onPressed: ScaffoldMessenger.of(context).clearSnackBars,
                  ),
                ),
              );
            }
          },
          buildWhen: (previous, current) => [
            PostTypeSelectedState,
            TimePickedState,
            PickedImageState,
            InputClearedState,
            PostingState,
            PostSuccessState,
            PostFailedState,
          ].contains(current.runtimeType),
          builder: (context, state) {
            if (state is PostTypeSelectedState) {
              type = state.type;
              if (chosenTime == null) {
                timeController.text =
                    "Pick the approximate time when you $type it";
              }
            } else if (state is TimePickedState) {
              if (state.pickedTime != null) {
                chosenTime = state.pickedTime!;
                timeController.text = chosenTime!.format(context);
              }
            } else if (state is PickedImageState) {
              pickedImage = state.pickedImage;
            } else if (state is InputClearedState) {
              chosenTime = null;
              type = "lost";
              timeController.text =
                  "Pick the approximate time when you $type it";
              pickedImage = null;
              titleField.text = "";
              descriptionField.text = "";
              locationField.text = "";
            }
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsetsGeometry.all(16),
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    spacing: 16,
                    crossAxisAlignment: .center,
                    children: [
                      SizedBox(width: double.infinity),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            spacing: 16,
                            children: [
                              const Qstext("Post type: "),
                              ChoiceChip(
                                label: const Qstext("Lost"),
                                selected: type == "lost",
                                showCheckmark: false,
                                onSelected: (value) => context
                                    .read<CmBloc>()
                                    .add(PostTypeSelectedEvent(type)),
                              ),
                              ChoiceChip(
                                label: const Qstext("Found"),
                                showCheckmark: false,
                                selected: type == "found",
                                onSelected: (value) => context
                                    .read<CmBloc>()
                                    .add(PostTypeSelectedEvent(type)),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Qstext("Clear All?"),
                                  content: Qstext(
                                    "This will clear all the input values. Cannot be Undone!!",
                                  ),
                                  actions: [
                                    IconButton(
                                      onPressed: () {
                                        ctx.read<CmBloc>().add(
                                          InputClearEvent(),
                                        );
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(
                                        Icons.check_rounded,
                                        color: Colors.red,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            label: Qstext(
                              "Clear All",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: titleField,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF0C3621)),
                          ),
                          border: OutlineInputBorder(),
                          label: Qstext("Title"),
                        ),
                      ),
                      SizedBox(
                        height: 70,
                        child: TextFormField(
                          controller: descriptionField,
                          minLines: null,
                          maxLines: null,
                          expands: true,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF0C3621)),
                            ),
                            border: OutlineInputBorder(),
                            label: Qstext("Description"),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 70,
                        child: TextFormField(
                          controller: locationField,
                          maxLines: null,
                          minLines: null,
                          expands: true,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF0C3621)),
                            ),
                            border: OutlineInputBorder(),
                            label: Qstext("Location"),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: timeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF0C3621)),
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onTap: () async {
                          context.read<CmBloc>().add(
                            TimePickedEvent(
                              await showTimePicker(
                                context: context,
                                initialTime: chosenTime ?? TimeOfDay.now(),
                              ),
                            ),
                          );
                        },
                      ),
                      Card.outlined(
                        elevation: 16,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            style: BorderStyle.solid,
                            color: Color(0xFF62E3A3),
                            width: 2,
                          ),
                          borderRadius: BorderRadiusGeometry.circular(24),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () async {
                            if (!picker.supportsImageSource(
                              ImageSource.gallery,
                            )) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Qstext("Could not access gallery!"),
                                ),
                              );
                              return;
                            }
                            context.read<CmBloc>().add(
                              ImagePickedEvent(
                                await picker.pickImage(
                                  source: ImageSource.gallery,
                                ),
                              ),
                            );
                          },
                          child: pickedImage == null
                              ? SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: Qstext(
                                      "Choose an Image",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    24,
                                  ),
                                  child: Image.file(
                                    File(pickedImage!.path),
                                    width: 400,
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            if (state is PostingState) {
                              return;
                            }
                            context.read<CmBloc>().add(
                              AddPostEvent(
                                type,
                                titleField.text,
                                descriptionField.text,
                                locationField.text,
                                pickedImage == null
                                    ? null
                                    : File(pickedImage!.path),
                                chosenTime ?? TimeOfDay.now(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            fixedSize: Size(double.infinity, 48),
                          ),
                          child: state is PostingState
                              ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                  constraints: BoxConstraints.tight(
                                    Size(20, 20),
                                  ),
                                )
                              : Qstext(
                                  "Post",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
