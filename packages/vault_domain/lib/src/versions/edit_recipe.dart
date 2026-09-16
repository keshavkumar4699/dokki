/// `EditRecipe`: the serialisable list of ops between a version and its
/// parent (§5.3, §10.3).
///
/// This is the deviation from the brief that makes evicted versions
/// re-materializable and sync payloads small.
library;

import 'dart:convert';

import '../imaging/image_op.dart';

final class EditRecipe {
  const EditRecipe(this.ops);

  const EditRecipe.empty() : ops = const [];

  final List<ImageOp> ops;

  bool get isEmpty => ops.isEmpty;

  /// False iff any op is non-deterministic (e.g. ML background removal).
  bool get isDeterministic => ops.every((ImageOp op) => op.deterministic);

  EditRecipe append(ImageOp op) => EditRecipe([...ops, op]);

  /// Appends [more] ops; used when deriving from a parent chain.
  EditRecipe compose(EditRecipe more) => EditRecipe([...ops, ...more.ops]);

  String toJson() => jsonEncode(ops.map((ImageOp op) => op.toJson()).toList());

  static EditRecipe fromJson(String json) =>
      EditRecipe(ImageOp.listFromJson(json));

  @override
  bool operator ==(Object other) {
    if (other is! EditRecipe || other.ops.length != ops.length) {
      return false;
    }
    for (var i = 0; i < ops.length; i++) {
      if (ops[i] != other.ops[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(ops);

  @override
  String toString() => 'EditRecipe(${ops.length} ops)';
}
