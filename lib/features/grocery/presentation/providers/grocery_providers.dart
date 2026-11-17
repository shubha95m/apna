import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../data/repositories/grocery_repository_impl.dart';
import '../../domain/entities/grocery_item_entity.dart';
import '../../domain/repositories/grocery_repository.dart';

final groceryRepositoryProvider = Provider<GroceryRepository>((ref) {
  return GroceryRepositoryImpl(Supabase.instance.client);
});

final workspaceGroceryItemsProvider = FutureProvider<List<GroceryItemEntity>>((ref) async {
  final activeWorkspace = ref.watch(activeWorkspaceProvider);
  if (activeWorkspace == null) return [];
  final repo = ref.watch(groceryRepositoryProvider);
  return repo.getItems(activeWorkspace.id);
});
