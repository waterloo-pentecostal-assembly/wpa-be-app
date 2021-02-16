enum DeviceType { MOBILE, TABLET }

enum LayoutDimension { MEDIA_TILE_HEIGHT }

class LayoutFactory {
  final DeviceType deviceType;

  // Mobile Dimensions
  double mMediaTileHeight = 75.0;

  // Tablet dimensions
  double tMediaTileHeight = 120.0;

  LayoutFactory(this.deviceType);

  double getDimension(LayoutDimension layoutDimension) {
    switch (layoutDimension) {
      case LayoutDimension.MEDIA_TILE_HEIGHT:
        {
          if (deviceType == DeviceType.MOBILE) {
            return mMediaTileHeight;
          }
          return tMediaTileHeight;
        }
        break;
      default:
        {
          throw Exception('Invalid LayoutDimension type');
        }
        break;
    }
  }
}
