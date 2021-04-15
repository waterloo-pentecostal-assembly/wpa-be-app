enum DeviceType { MOBILE, TABLET }

enum LayoutDimension {
  ADMIN_TILE_HEIGHT,
  ADMIN_TILE_WIDTH,
  ADMIN_TILE_FONT_SIZE,
  ADMIN_ICON_SIZE,
  CONTENT_TAB_HEIGHT,
  CONTENT_TAB_WIDTH,
}

class LayoutFactory {
  final DeviceType deviceType;

  //General Conversion Value
  double conversionVal = 5 / 3;

  // Mobile Dimensions
  double mContentTabHeight = 108;
  double mContentTabWidth = 70;
  double mAdminTileHeight = 125;
  double mAdminTileWidth = 150;
  double mAdminTileFontSize = 14.0;
  double mAdminIconSize = 50;

  // Tablet dimensions
  double tContentTabHeight = 144;
  double tContentTabWidth = 93;
  double tAdminTileHeight = 300;
  double tAdminTileWidth = 375;
  double tAdminTileFontSize = 14.0;
  double tAdminIconSize = 110;

  LayoutFactory(this.deviceType);

  double getDimension(LayoutDimension layoutDimension) {
    switch (layoutDimension) {
      case LayoutDimension.CONTENT_TAB_HEIGHT:
        {
          if (deviceType == DeviceType.MOBILE) {
            return mContentTabHeight;
          }
          return tContentTabHeight;
        }
        break;
      case LayoutDimension.CONTENT_TAB_WIDTH:
        {
          if (deviceType == DeviceType.MOBILE) {
            return mContentTabWidth;
          }
          return tContentTabWidth;
        }
        break;
      case LayoutDimension.ADMIN_TILE_HEIGHT:
        {
          if (deviceType == DeviceType.MOBILE) {
            return mAdminTileHeight;
          }
          return tAdminTileHeight;
        }
        break;
      case LayoutDimension.ADMIN_TILE_WIDTH:
        {
          if (deviceType == DeviceType.MOBILE) {
            return mAdminTileWidth;
          }
          return tAdminTileWidth;
        }
        break;
      case LayoutDimension.ADMIN_TILE_FONT_SIZE:
        {
          if (deviceType == DeviceType.MOBILE) {
            return mAdminTileFontSize;
          }
          return tAdminTileFontSize;
        }
        break;
      case LayoutDimension.ADMIN_ICON_SIZE:
        {
          if (deviceType == DeviceType.MOBILE) {
            return mAdminIconSize;
          }
          return tAdminIconSize;
        }
        break;
      default:
        {
          throw Exception('Invalid LayoutDimension type');
        }
        break;
    }
  }

  double conversion() {
    if (deviceType == DeviceType.TABLET) {
      return conversionVal;
    }
    return 1.0;
  }
}
