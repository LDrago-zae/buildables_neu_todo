import 'location_model.dart';

class MapState{
  late final LocationModel? curretLocation;

  MapState({required this.curretLocation});

  MapState copyWith({LocationModel? curretLocation}){
    return MapState(
      curretLocation: curretLocation ?? this.curretLocation,
    );
  }
}