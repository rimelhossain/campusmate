import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/model/lost_and_found_item.dart';
import 'package:campusmate/ui/components/qstext.dart';
import 'package:campusmate/ui/components/response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LostAndFoundDetails extends StatefulWidget {
  final LostAndFoundItem item;
  const LostAndFoundDetails(this.item, {super.key});

  @override
  State<LostAndFoundDetails> createState() => _LostAndFoundDetailsState();
}

class _LostAndFoundDetailsState extends State<LostAndFoundDetails> {
  final responseController = TextEditingController();

  double? calculateImageHeight() {
    double? calculatedHeight;
    widget.item.imageProvider
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((info, _) {
            final width = info.image.width.toDouble();
            final height = info.image.height.toDouble();

            calculatedHeight = 300 * (height / width);
          }),
        );
    return calculatedHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      persistentFooterButtons: [
        TextFormField(
          enabled: !widget.item.isResolved,
          controller: responseController,
          decoration: InputDecoration(
            contentPadding: EdgeInsetsGeometry.all(8),
            hint: Qstext("Respond"),
            suffixIcon: IconButton(
              onPressed: () {
                if (responseController.value.text.isNotEmpty &&
                    !widget.item.isResolved) {
                  context.read<CmBloc>().add(
                    AddResponseEvent(
                      responseController.value.text.trim(),
                      widget.item.id,
                    ),
                  );
                  responseController.text = "";
                }
              },
              icon: Icon(Icons.send, color: Colors.deepOrange),
            ),
          ),
        ),
      ],
      body: BlocConsumer<CmBloc, CmState>(
        listener: (context, state) {
          if (state is AddResponseErrorState) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Qstext(state.msg)));
          } else if (state is AddResponseSuccessState) {
            context.read<CmBloc>().add(LoadResponsesEvent(widget.item.id));
          } else if (state is LoadResponsesErrorState) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Qstext(state.msg)));
          } else if (state is ResolveErrorState) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Qstext(state.msg)));
          }
        },
        builder: (context, state) {
          Widget responses = LinearProgressIndicator();
          if (state is LoadResponsesSuccessState) {
            responses = SingleChildScrollView(
              child: Column(
                children: state.responses
                    .map(
                      (e) => Response(
                        e['username'] ?? "Unknown",
                        e['description'] ?? "No Description",
                      ),
                    )
                    .toList(),
              ),
            );
          } else if (state is LoadResponsesErrorState) {
            responses = Qstext("failed to load responses");
          } else {
            context.read<CmBloc>().add(LoadResponsesEvent(widget.item.id));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: calculateImageHeight(),
                automaticallyImplyLeading: false,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Back",
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                  icon: Icon(Icons.arrow_back),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 2,
                  background: Hero(
                    tag: widget.item.id,
                    child: Image(
                      image: widget.item.imageProvider,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                pinned: true,
              ),
              SliverPadding(
                padding: EdgeInsetsGeometry.all(16),
                sliver: SliverFillRemaining(
                  hasScrollBody: true,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilledButton(
                          onPressed: widget.item.isResolved
                              ? null
                              : () => context.read<CmBloc>().add(
                                  ResolvedRequestedEvent(widget.item),
                                ),
                          child: Qstext(
                            "${widget.item.type.toUpperCase()} ${widget.item.isResolved ? '(Resolved)' : '(Unresolved - click here to mark it as resolved)'}",
                          ),
                        ),
                        SizedBox(height: 16),
                        Qstext(
                          "Title",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Qstext(
                            widget.item.title,
                            style: TextStyle(fontWeight: FontWeight.w400),
                          ),
                        ),
                        SizedBox(height: 16),
                        Qstext(
                          "Description",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Qstext(
                            widget.item.description,
                            style: TextStyle(fontWeight: FontWeight.w400),
                          ),
                        ),
                        SizedBox(height: 16),
                        Qstext(
                          "Location",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Qstext(
                            widget.item.location,
                            style: TextStyle(fontWeight: FontWeight.w400),
                          ),
                        ),
                        SizedBox(height: 16),
                        Qstext(
                          "Responses",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 16),
                        responses,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
