import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/model/lost_and_found_item.dart';
import 'package:campusmate/ui/components/qstext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LostAndFoundDetails extends StatefulWidget {
  final LostAndFoundItem item;
  const LostAndFoundDetails(this.item, {super.key});

  @override
  State<LostAndFoundDetails> createState() => _LostAndFoundDetailsState();
}

class _LostAndFoundDetailsState extends State<LostAndFoundDetails> {
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
          decoration: InputDecoration(
            contentPadding: EdgeInsetsGeometry.all(8),
            hint: Qstext("Respond"),
            suffixIcon: IconButton(
              onPressed: () {},
              icon: Icon(Icons.send, color: Colors.deepOrange),
            ),
          ),
        ),
      ],
      body: BlocBuilder<CmBloc, CmState>(
        builder: (context, state) {
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
                        Container(
                          height: 28,
                          width: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFF534227),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Qstext(
                              widget.item.type.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                        Qstext("Responses", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                        
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
