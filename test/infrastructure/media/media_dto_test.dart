import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:wpa_app/domain/media/entities.dart';
import 'package:wpa_app/infrastructure/common/firebase_storage_helper.dart';
import 'package:wpa_app/infrastructure/media/media_dto.dart';

class MockFirebaseStorageHelper extends Mock implements FirebaseStorageHelper {}

void main() {
  MockFirebaseStorageHelper mockFirebaseStorageHelper;
  // GetIt getIt;

  setUp(() {
    mockFirebaseStorageHelper = MockFirebaseStorageHelper();
    // getIt = GetIt.instance;

    // getIt.registerLazySingleton<FirebaseStorageHelper>(() => mockFirebaseStorageHelper);
  });

  test('should return valid Media object based on Json input', () async {
    // arrange
    final Map<String, dynamic> validMediaJson = {
      "description": "description",
      "platform": "platform",
      "link": "link",
      "thumbnail_gs_location": "thumbnail_gs_location"
    };

    when(mockFirebaseStorageHelper.getDownloadUrl(any)).thenAnswer((_) async => 'thumbnail_download_url');

    // act
    final Media mediaObject =
        await MediaDto.fromJson(validMediaJson).copyWith(id: "id").toDomain(mockFirebaseStorageHelper);

    //assert
    expect(mediaObject.id, "id");
    expect(mediaObject.description, "description");
    expect(mediaObject.link, "link");
    expect(mediaObject.platform, "platform");
    expect(mediaObject.thumbnailUrl, "thumbnail_download_url");
  });
}
