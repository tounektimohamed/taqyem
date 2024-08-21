'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "383e55f7f3cce5be08fcf1f3881f585c",
"canvaskit/skwasm.js.symbols": "c3c05bd50bdf59da8626bbe446ce65a3",
"canvaskit/skwasm.js": "5d4f9263ec93efeb022bb14a3881d240",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"canvaskit/chromium/canvaskit.js.symbols": "ee7e331f7f5bbf5ec937737542112372",
"canvaskit/chromium/canvaskit.js": "901bb9e28fac643b7da75ecfd3339f3f",
"canvaskit/chromium/canvaskit.wasm": "399e2344480862e2dfa26f12fa5891d7",
"canvaskit/skwasm.wasm": "4051bfc27ba29bf420d17aa0c3a98bce",
"canvaskit/canvaskit.js.symbols": "74a84c23f5ada42fe063514c587968c6",
"canvaskit/canvaskit.js": "738255d00768497e86aa4ca510cce1e1",
"canvaskit/canvaskit.wasm": "9251bb81ae8464c4df3b072f84aa969b",
"flutter_bootstrap.js": "865dfcfcc4d769b875e615293e1a3237",
"index.html": "e858b9888da66057b357ba6823c0102c",
"/": "e858b9888da66057b357ba6823c0102c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"main.dart.js": "e120a425e7b59e16a26606130c5bb2d6",
"manifest.json": "3fc29f9294b755bca0378065b89e216e",
"version.json": "e705f5375e538c89ae22742e203f00dc",
"cigle-meh.png": "05eb7a91084245f37cb4bba345c80374",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "1b5634953f2674404ac41a77135a0357",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/packages/google_places_flutter/images/location.json": "afa33acf2c340246c901718f4efdfccf",
"assets/packages/floating_snackbar/assets/image/flutter_02.png": "6aa8464adbaf2dc20a6e34f2695a61fc",
"assets/packages/alarm/assets/long_blank.mp3": "d632dd58e2137a2e67849c108d5eb4b6",
"assets/packages/alarm/assets/not_blank.mp3": "71ac239a121767241ccfcc1b625d44e7",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "eafdfd1fe143602951db6ff91b4e5b4e",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "87d86c3427953ab8467786c58064f462",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "f3307f62ddff94d2cd8b103daf8d1b0f",
"assets/packages/day_night_time_picker/assets/moon.png": "71137650ab728a466a50fa4fa78fb2b9",
"assets/packages/day_night_time_picker/assets/sun.png": "5fd1657bcb73ce5faafde4183b3dab22",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/lib/assets/user.png": "6620d99d7d02e89a5c379af73293d794",
"assets/lib/assets/icons/me/menagment.gif": "9ee8942574f125253964073ad231634b",
"assets/lib/assets/icons/me/logo.png": "963f2210655c1cb3018c395cf45f6872",
"assets/lib/assets/icons/me/news.gif": "4eb945eec0590f430da2b6fc4e6d9594",
"assets/lib/assets/icons/me/news1.gif": "5616a0980f980798816cc24db52a493d",
"assets/lib/assets/icons/me/caroussel.png": "1c33eb984631bf7fae52ec5263e196ac",
"assets/lib/assets/icons/me/flutter_carousel_OG_Image_9cbaf3e582.png": "931d7ceab471425deb17a29f1e80c93a",
"assets/lib/assets/icons/me/profil.jpg": "ec22daa47747a8cb5114afa132730416",
"assets/lib/assets/icons/me/service.gif": "db0227f67927da081a0f7c5a4d095c1a",
"assets/lib/assets/icons/me/admin1.gif": "ce48ed5b8c4038a0d9712b1c35b11779",
"assets/lib/assets/icons/me/mokup.png": "e8c3018ca3d31e7c8c0eb3340671b5e9",
"assets/lib/assets/icons/me/plan.png": "2e59f40e59eab3a39f544926abf980a7",
"assets/lib/assets/icons/me/maps.gif": "8069fd3e8e3a641261e2dc50b59531ba",
"assets/lib/assets/icons/me/admin2.gif": "d17ff9937581a75cf33711d056343596",
"assets/lib/assets/icons/me/admin4.gif": "e89657199c53d1f05d5c46b2353dcc3f",
"assets/lib/assets/icons/me/subscribers.gif": "bc2d3dcf57cf17c833c933dd85b1e42d",
"assets/lib/assets/icons/me/admin3.gif": "00af01fc0b1e3d819779c347789ee8d4",
"assets/lib/assets/icons/me/logout.gif": "5f675de67cba9ce24c6c26b9fccbe03c",
"assets/lib/assets/icons/me/cigle-meh.png": "05eb7a91084245f37cb4bba345c80374",
"assets/lib/assets/icons/me/Instagram-Carousels.svg": "d35f5527f5e571127422ff46a868b22d",
"assets/lib/assets/icons/2.gif": "34614821da9e5dca593852b83d1c3ea7",
"assets/lib/l10n/app_en.arb": "8c43ebeed7f0f2606e123bd1cb4f61a0",
"assets/lib/l10n/app_si.arb": "92cb71ff09dd5afa2e16173deb8d61ef",
"assets/FontManifest.json": "5a32d4310a6f5d9a6b651e75ba0d7372",
"assets/AssetManifest.bin.json": "d2d56f6920881140671698c9f8f76ebd",
"assets/AssetManifest.json": "743ad16063072d8756f5bd03d85b34f7",
"assets/fonts/MaterialIcons-Regular.otf": "d4315d08640389e5d5994069dad5491d",
"assets/AssetManifest.bin": "5b1f80d13482334999b9831213cb65d5",
"assets/NOTICES": "a40effe11767c7c59d5a43f2cfa43081",
"assets/assets/videos/login.mp4": "a14b885d71af2ef1a20749a1bcf22c6c",
"assets/assets/tataouine.geojson": "4fe574b38e2adc5c688b355f1e141aff",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/cigle-meh.png": "05eb7a91084245f37cb4bba345c80374",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
