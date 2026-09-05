package com.dartnative.share

import androidx.core.content.FileProvider

/**
 * Custom `FileProvider` subclass — prevents manifest `<provider>` authority
 * collisions when multiple libraries register their own providers in the host
 * app. See:
 * https://developer.android.com/guide/topics/manifest/provider-element
 */
class ShareFileProvider : FileProvider()
