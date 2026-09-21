import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/model/lost_and_found_item.dart';
import 'package:campusmate/ui/components/qstext.dart';
import 'package:campusmate/ui/components/response.dart';
import 'package:campusmate/utils/constants.dart';
import 'package:campusmate/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LostAndFoundDetails extends StatefulWidget {
  final LostAndFoundItem item;
  const LostAndFoundDetails(this.item, {super.key});

  @override
  State<LostAndFoundDetails> createState() => _LostAndFoundDetailsState();
}

class _LostAndFoundDetailsState extends State<LostAndFoundDetails> {
  final responseField = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CmBloc, CmState>(
      listenWhen: (previous, current) => current is AddResponseErrorState,
      listener: (context, state) {
        if (state is AddResponseErrorState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Qstext(state.msg)));
        }
      },
      builder: (context, state) => Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Qstext("Details")),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(10),
                      child: Hero(
                        tag: widget.item.id,
                        child: widget.item.imageProvider == null
                            ? Center(
                                child: Qstext(
                                  "No Image",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Image(
                                image: widget.item.imageProvider!,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Qstext(
                                        "Could Not Load Image",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                fit: BoxFit.fitWidth,
                              ),
                      ),
                    ),
                  ),
                  widget.item.authorId ==
                          Supabase.instance.client.auth.currentUser!.id
                      ? ElevatedButton(
                          onPressed: widget.item.isResolved
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Qstext("Mark as Resolved?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            context.read<CmBloc>().add(
                                              ResolvedRequestedEvent(
                                                widget.item,
                                              ),
                                            );
                                          },
                                          child: Qstext(
                                            "Yes, Confirm Resolve",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                          },
                                          child: Qstext(
                                            "No, Keep unresolved",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          child: Qstext(
                            "${widget.item.type.toUpperCase()}${widget.item.isResolved ? ' (Resolved)' : ' - Click Here to mark as Resolved'}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : Container(
                          height: 48,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Qstext(
                              "${widget.item.type.toUpperCase()}${widget.item.isResolved ? ' (Resolved)' : ''}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Qstext(
                          "Author Info",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Row(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              child: Image.network(
                                widget.item.userPhotoUrl,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(
                                      "assets/images/default-avatar.png",
                                    ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 4,
                              children: [
                                Qstext(
                                  capitalizePerWords(widget.item.username),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Qstext(
                                  widget.item.userSid,
                                  style: TextStyle(color: Colors.blueGrey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DetailUnit("Title", widget.item.title),
                  DetailUnit("Description", widget.item.description),
                  DetailUnit(
                    "Location",
                    widget.item.location,
                    iconData: Icons.location_on,
                  ),
                  DetailUnit(
                    "Approximate Time",
                    widget.item.time.format(context),
                  ),
                  Divider(),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        context.read<CmBloc>().add(
                          LoadResponsesEvent(widget.item.id),
                        );
                        showModalBottomSheet(
                          context: context,
                          elevation: 4,
                          enableDrag: true,
                          showDragHandle: true,
                          barrierLabel: "Responses",
                          useSafeArea: true,
                          isScrollControlled: true,
                          builder: (ctx) =>
                              Responses(widget.item.id, widget.item),
                        );
                      },
                      child: Qstext(
                        "Show Responses",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailUnit extends StatelessWidget {
  final String title;
  final String detail;
  final IconData? iconData;
  const DetailUnit(this.title, this.detail, {this.iconData, super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> detailRow = [
      Qstext(
        detail,
        style: TextStyle(
          overflow: TextOverflow.visible,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
    if (iconData != null) {
      detailRow.insert(0, Icon(iconData));
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: BoxBorder.all(color: const Color.fromARGB(255, 98, 187, 101)),
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Qstext(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Wrap(direction: Axis.horizontal, children: detailRow),
        ],
      ),
    );
  }
}

class Responses extends StatefulWidget {
  final String postId;
  final LostAndFoundItem item;

  const Responses(this.postId, this.item, {super.key});

  @override
  State<Responses> createState() => _ResponsesState();
}

class _ResponsesState extends State<Responses> {
  final responseField = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CmBloc, CmState>(
      listenWhen: (previous, current) =>
          current is AddResponseSuccessState ||
          current is AddResponseErrorState,
      listener: (context, state) {
        if (state is AddResponseSuccessState) {
          context.read<CmBloc>().add(LoadResponsesEvent(widget.postId));
        } else if (state is AddResponseErrorState) {
          FocusManager.instance.primaryFocus?.unfocus();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Qstext(state.msg)));
        }
      },
      buildWhen: (previous, current) =>
          current is LoadResponsesSuccessState ||
          current is LoadResponsesErrorState,
      builder: (context, state) {
        if (state is LoadResponsesErrorState) {
          return Center(child: Qstext("Responses Failed Load!!!"));
        } else if (state is LoadResponsesSuccessState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 8.0,
              left: 8.0,
              right: 8.0,
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Qstext(
                        "Responses",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Divider(),
                Expanded(
                  child: state.responses.isEmpty
                      ? Center(
                          child: Qstext(
                            "No responses yet!!!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            spacing: 16,
                            children: state.responses
                                .map(
                                  (e) => Response(
                                    e['username'],
                                    e['sid'],
                                    e['description'],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
                SafeArea(
                  child: TextFormField(
                    enabled: !widget.item.isResolved,
                    controller: responseField,
                    onFieldSubmitted: (value) {
                      if (value.isNotEmpty && !widget.item.isResolved) {
                        context.read<CmBloc>().add(
                          AddResponseEvent(value.trim(), widget.item.id),
                        );
                        responseField.text = "";
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsetsGeometry.all(8),
                      border: OutlineInputBorder(),
                      hint: Qstext("Respond"),
                      suffixIcon: IconButton(
                        onPressed: () {
                          if (responseField.value.text.isNotEmpty &&
                              !widget.item.isResolved) {
                            context.read<CmBloc>().add(
                              AddResponseEvent(
                                responseField.value.text.trim(),
                                widget.item.id,
                              ),
                            );
                            responseField.text = "";
                          }
                        },
                        icon: Icon(Icons.send, color: Colors.deepOrange),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(child: LinearProgressIndicator());
        }
      },
    );
  }
}
