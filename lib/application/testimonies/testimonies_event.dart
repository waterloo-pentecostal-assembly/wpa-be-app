part of 'testimonies_bloc.dart';

abstract class TestimoniesEvent extends Equatable {
  const TestimoniesEvent();

  @override
  List<Object> get props => [];
}

class RecentTestimoniesRequested extends TestimoniesEvent {
  final int amount;

  RecentTestimoniesRequested({required this.amount});
  @override
  List<Object> get props => [amount];
}

class TestimoniesRequested extends TestimoniesEvent {
  final int amount;

  TestimoniesRequested({required this.amount});

  @override
  List<Object> get props => [amount];
}

class TestimonyReported extends TestimoniesEvent {
  final String id;

  TestimonyReported({required this.id});

  @override
  List<Object> get props => [id];
}

class MyTestimoniesRequested extends TestimoniesEvent {
  MyTestimoniesRequested();

  @override
  List<Object> get props => [];
}

class MyTestimonyDeleted extends TestimoniesEvent {
  final String id;

  MyTestimonyDeleted({required this.id});

  @override
  List<Object> get props => [id];
}

class MoreTestimoniesRequested extends TestimoniesEvent {
  final int amount;

  MoreTestimoniesRequested({required this.amount});

  @override
  List<Object> get props => [amount];
}

class NewTestimonyCreated extends TestimoniesEvent {
  final String request;
  final bool isAnonymous;

  NewTestimonyCreated({required this.request, required this.isAnonymous});

  @override
  List<Object> get props => [request, isAnonymous];
}

class PraiseTestimony extends TestimoniesEvent {
  final String id;

  PraiseTestimony({required this.id});

  @override
  List<Object> get props => [id];
}

class NewTestimonyStarted extends TestimoniesEvent {
  NewTestimonyStarted();

  @override
  List<Object> get props => [];
}

class NewTestimonyRequestChanged extends TestimoniesEvent {
  final String testimony;

  NewTestimonyRequestChanged({required this.testimony});

  @override
  List<Object> get props => [testimony];
}

class NewTestimonyAnonymousChanged extends TestimoniesEvent {
  final bool isAnonymous;

  NewTestimonyAnonymousChanged({required this.isAnonymous});

  @override
  List<Object> get props => [isAnonymous];
}

class CloseTestimony extends TestimoniesEvent {
  final String id;

  CloseTestimony({required this.id});

  @override
  List<Object> get props => [id];
}

class MyArchivedTestimoniesRequested extends TestimoniesEvent {
  MyArchivedTestimoniesRequested();
  @override
  List<Object> get props => [];
}
