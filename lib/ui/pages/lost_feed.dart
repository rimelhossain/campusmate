import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/model/lost_and_found_item.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/ui/components/lost_and_found_card.dart';
import 'package:campusmate/ui/pages/create_post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LostFeed extends StatefulWidget {
  const LostFeed({super.key});

  @override
  State<LostFeed> createState() => _LostFeedState();
}

class _LostFeedState extends State<LostFeed> {
  Future<List<LostAndFoundItem>>? items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: ((context) => CreatePost())),
        ),
        label: Qstext("Add New"),
        icon: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Qstext("Lost and Found"),
        actions: [
          PopupMenuButton(
            tooltip: "More",
            itemBuilder: (ctx) => [
              PopupMenuItem(
                onTap: () => ctx.read<CmBloc>().add(LoadItemsEvent()),
                child: Qstext("Refresh"),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<CmBloc, CmState>(
          buildWhen: (previous, current) => [
            ItemLoadedState,
            ItemsLoadFailedState,
            ItemsLoadingState,
          ].contains(current.runtimeType),
          builder: (context, state) {
            if (state is ItemLoadedState) {
              if (state.items.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 24,
                  children: [
                    SizedBox(width: double.infinity),
                    Qstext("No Posts made yet!!!"),
                    FilledButton(
                      onPressed: () =>
                          context.read<CmBloc>().add(LoadItemsEvent()),
                      child: Qstext("Reload"),
                    ),
                  ],
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<CmBloc>().add(LoadItemsEvent()),
                elevation: 4,
                triggerMode: RefreshIndicatorTriggerMode.onEdge,
                child: ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsetsGeometry.all(24),
                  itemCount: state.items.length,
                  itemBuilder: (ctx, i) => LostAndFoundCard(state.items[i]),
                ),
              );
            } else if (state is ItemsLoadFailedState) {
              return Center(child: Qstext(state.msg));
            } else {
              context.read<CmBloc>().add(LoadItemsEvent());
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
