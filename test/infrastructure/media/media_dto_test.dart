import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wpa_app/domain/media/entities.dart';
import 'package:wpa_app/services/firebase_storage_service.dart';
import 'package:wpa_app/infrastructure/media/media_dto.dart';

class MockFirebaseStorageService extends Mock implements FirebaseStorageService {}

void main() {
  MockFirebaseStorageService mockFirebaseStorageService;
  // GetIt getIt;

  setUp(() {
    mockFirebaseStorageService = MockFirebaseStorageService();
    // getIt = GetIt.instance;

    // getIt.registerLazySingleton<FirebaseStorageHelper>(() => mockFirebaseStorageService);
  });

  test('should return valid Media object based on Json input', () async {
    // arrange
    final Map<String, dynamic> validMediaJson = {
      "description": "description",
      "platform": "platform",
      "link": "link",
      "thumbnail_gs_location": "thumbnail_gs_location"
    };

    when(mockFirebaseStorageService.getDownloadUrl(any)).thenAnswer((_) async => 'thumbnail_download_url');

    // act
    final Media mediaObject =
        await MediaDto.fromJson(validMediaJson).copyWith(id: "id").toDomain(mockFirebaseStorageService);

    //assert
    expect(mediaObject.id, "id");
    expect(mediaObject.description, "description");
    expect(mediaObject.link, "link");
    expect(mediaObject.platform, "platform");
    expect(mediaObject.thumbnailUrl, "thumbnail_download_url");
  });
}
