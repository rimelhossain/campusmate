import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/ui/components/lost_and_found_card.dart';
import 'package:campusmate/ui/pages/create_post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LostFeed extends StatelessWidget {
  const LostFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: const TabBar(
            tabs: [
              Tab(text: "Unresolved"),
              Tab(text: "Resolved"),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [FilteredPosts(false), FilteredPosts(true)],
          ),
        ),
      ),
    );
  }
}

class FilteredPosts extends StatelessWidget {
  final bool showResolved;

  const FilteredPosts(this.showResolved, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: BlocBuilder<CmBloc, CmState>(
        buildWhen: (previous, current) =>
            current is ItemLoadedState ||
            current is ItemsLoadFailedState ||
            current is ItemsLoadingState ||
            current is ResolveSuccessState ||
            current is PostSuccessState,
        builder: (ctx, state) {
          if (state is ItemsLoadFailedState) {
            return Center(
              child: Qstext(state.msg, style: TextStyle(fontSize: 24)),
            );
          } else if (state is ItemsLoadingState) {
            return Center(child: CircularProgressIndicator());
          } else if (state is ItemLoadedState) {
            final items = state.items
                .where(
                  // item.isResolved XOR showResolved
                  (item) =>
                      !item.isResolved && !showResolved ||
                      item.isResolved && showResolved,
                )
                .toList();
            if (items.isEmpty) {
              return Center(
                child: Qstext(
                  "Nothing Here!!!",
                  style: TextStyle(fontSize: 24),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ctx.read<CmBloc>().add(LoadItemsEvent()),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => LostAndFoundCard(items[index]),
              ),
            );
          } else {
            ctx.read<CmBloc>().add(LoadItemsEvent());
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
