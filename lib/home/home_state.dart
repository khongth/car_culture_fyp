part of 'home_cubit.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Map<String, dynamic>> posts;

  HomeLoaded({required this.posts});
}

class HomeError extends HomeState {
  final String message;

  HomeError({required this.message});
}

class HomeMessagePosted extends HomeState {}

class HomeSignedOut extends HomeState {}
