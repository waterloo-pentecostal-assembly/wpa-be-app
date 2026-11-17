import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/common/exceptions.dart';
import '../../domain/links/entities.dart';
import '../../domain/links/interface.dart';
import '../common/load_status.dart';

class LinksState extends Equatable {
  const LinksState({
    this.status = LoadStatus.initial,
    this.links = const AppLinks(),
    this.errorMessage,
  });

  final LoadStatus status;
  final AppLinks links;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, links, errorMessage];
}

/// Configured external links (give, privacy policy, terms, help/report email).
class LinksCubit extends Cubit<LinksState> {
  LinksCubit(this._repository) : super(const LinksState());

  final ILinksRepository _repository;

  Future<void> load() async {
    try {
      final links = await _repository.getLinks();
      if (!isClosed) {
        emit(LinksState(status: LoadStatus.success, links: links));
      }
    } catch (e) {
      if (!isClosed) {
        emit(LinksState(
          status: LoadStatus.failure,
          errorMessage: userMessageFor(e, fallback: 'An unknown error occured'),
        ));
      }
    }
  }
}
