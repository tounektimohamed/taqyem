'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "888483df48293866f9f41d3d9274a779",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"cigle-meh1.png": "284748a4dc9389c24322b146a734b185",
"flutter_bootstrap.js": "27d5221716c81f4cf22d0ba42b486d75",
"index.html": "7469ca4c81aa9b5705ec4883cdabb0bc",
"/": "7469ca4c81aa9b5705ec4883cdabb0bc",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"main.dart.js": "df2fafa07c46a89f7956d86e801bcfb8",
"manifest.json": "965e805278c4f5310bd80fad84837a3d",
"version.json": "ac1f6703e8c99aba74b092e187c04468",
"cigle-meh.png1": "d408ef75ce32b9f943c3f1c63432baf2",
"cigle-meh.png": "da9d6d292230d24cae0d1c70c6875a69",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "551fbdd0a87debed9a8e444a6cf7e0d9",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/google_places_flutter/images/location.json": "afa33acf2c340246c901718f4efdfccf",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/packages/floating_snackbar/assets/image/fsb-ss.png": "6535fe9c4c36109e5976843219e263fb",
"assets/packages/font_awesome_flutter/lib/fonts/Font%2520Awesome%25207%2520Brands-Regular-400.otf": "f190229e68100d2f97524038402c6d91",
"assets/packages/font_awesome_flutter/lib/fonts/Font%2520Awesome%25207%2520Free-Solid-900.otf": "e151d7a6f42f17e9ea335c91d07b3739",
"assets/packages/font_awesome_flutter/lib/fonts/Font%2520Awesome%25207%2520Free-Regular-400.otf": "df86a1976d76bd04cf3fcaf5add2dd0f",
"assets/packages/day_night_time_picker/assets/moon.png": "71137650ab728a466a50fa4fa78fb2b9",
"assets/packages/day_night_time_picker/assets/sun.png": "5fd1657bcb73ce5faafde4183b3dab22",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/lib/assets/user.png": "6620d99d7d02e89a5c379af73293d794",
"assets/lib/assets/icons/me/menagment.gif": "9ee8942574f125253964073ad231634b",
"assets/lib/assets/icons/me/logo.png": "da9d6d292230d24cae0d1c70c6875a69",
"assets/lib/assets/icons/me/barm.gif": "512711cb593b6226db8fdea881bdd78d",
"assets/lib/assets/icons/me/news.gif": "4eb945eec0590f430da2b6fc4e6d9594",
"assets/lib/assets/icons/me/222.png": "284748a4dc9389c24322b146a734b185",
"assets/lib/assets/icons/me/cigle-meh2.png": "05eb7a91084245f37cb4bba345c80374",
"assets/lib/assets/icons/me/isens_thumb-removebg-preview.png": "d60c7a641dff6009563edc6bc03f0c1f",
"assets/lib/assets/icons/me/QZJI.gif": "9cc63f72ac8f5d18fa69b04dcc16eec2",
"assets/lib/assets/icons/me/15-13-33-168_512.gif": "f55c8c902ffe9667ce5283178198e69a",
"assets/lib/assets/icons/me/note.gif": "ef3bb8a8bb4d6b6d0e627a1dd1f65d80",
"assets/lib/assets/icons/me/news1.gif": "5616a0980f980798816cc24db52a493d",
"assets/lib/assets/icons/me/share_report.gif": "e89657199c53d1f05d5c46b2353dcc3f",
"assets/lib/assets/icons/me/caroussel.png": "1c33eb984631bf7fae52ec5263e196ac",
"assets/lib/assets/icons/me/flutter_carousel_OG_Image_9cbaf3e582.png": "931d7ceab471425deb17a29f1e80c93a",
"assets/lib/assets/icons/me/profil.jpg": "ec22daa47747a8cb5114afa132730416",
"assets/lib/assets/icons/me/permis_debati-removebg-preview.png": "528b4efff918049dc276b79b041775a3",
"assets/lib/assets/icons/me/ministere.png": "55bc08b7279f3141568cd66bd5dabf01",
"assets/lib/assets/icons/me/results.gif": "db0227f67927da081a0f7c5a4d095c1a",
"assets/lib/assets/icons/me/logo2.png": "d408ef75ce32b9f943c3f1c63432baf2",
"assets/lib/assets/icons/me/mokup.png": "e8c3018ca3d31e7c8c0eb3340671b5e9",
"assets/lib/assets/icons/me/logo1.png": "963f2210655c1cb3018c395cf45f6872",
"assets/lib/assets/icons/me/plan.png": "2e59f40e59eab3a39f544926abf980a7",
"assets/lib/assets/icons/me/L7.gif": "f14cee218a099e9046f243d6b00509af",
"assets/lib/assets/icons/me/maps.gif": "8069fd3e8e3a641261e2dc50b59531ba",
"assets/lib/assets/icons/me/notification.gif": "d17ff9937581a75cf33711d056343596",
"assets/lib/assets/icons/me/G-carrousel.png": "e7fe39114a8fdeb890456c02cba0cce5",
"assets/lib/assets/icons/me/realisations-16918-removebg-preview.png": "26530424bb944351034c2384729b6c3e",
"assets/lib/assets/icons/me/assessment.gif": "ce48ed5b8c4038a0d9712b1c35b11779",
"assets/lib/assets/icons/me/plan%2520de%2520lotissement.png": "c9a04bc1252c8ff9b978e1173ef64019",
"assets/lib/assets/icons/me/subscribers.gif": "bc2d3dcf57cf17c833c933dd85b1e42d",
"assets/lib/assets/icons/me/logout.gif": "5f675de67cba9ce24c6c26b9fccbe03c",
"assets/lib/assets/icons/me/cigle-meh.png": "f80c968ef9a6edebfcf9192b7ec219bb",
"assets/lib/assets/icons/me/support_woman_16-9.gif": "cbf2cfb894bcbf7da9790b26271c96bf",
"assets/lib/assets/icons/me/unnamed.gif": "6fc6b92fc13cd95b1be08e08d6365ac6",
"assets/lib/assets/icons/me/PAU.png": "859f723e5feab0a784e87e149982889f",
"assets/lib/assets/icons/me/ajout%2520des%2520images.png": "ea02a81336e16af72e6092a60cdc7325",
"assets/lib/assets/icons/me/ajouter.gif": "97feb9f890995ccdc3779aa6e893cce6",
"assets/lib/assets/icons/me/progress.gif": "00af01fc0b1e3d819779c347789ee8d4",
"assets/lib/assets/icons/me/permit%2520de%2520batis.png": "016218e517374b6eb5f43f68d078d45d",
"assets/lib/assets/icons/me/Instagram-Carousels.svg": "d35f5527f5e571127422ff46a868b22d",
"assets/lib/assets/icons/2.gif": "34614821da9e5dca593852b83d1c3ea7",
"assets/lib/l10n/app_localizations_en.dart": "3f7cc662d8fb2c06399471e7a8464624",
"assets/lib/l10n/app_en.arb": "8c43ebeed7f0f2606e123bd1cb4f61a0",
"assets/lib/l10n/app_localizations_si.dart": "c6dafdd6a69e0173cc495056972c3f45",
"assets/lib/l10n/app_localizations.dart": "50a3c1b18fb51a835bf6b00ae3109c71",
"assets/lib/l10n/app_si.arb": "92cb71ff09dd5afa2e16173deb8d61ef",
"assets/FontManifest.json": "97c2528ecc2fbf4093965257fdba1854",
"assets/AssetManifest.bin.json": "7649773892b0d57391c175d9907931ab",
"assets/AssetManifest.json": "71482f1ffca7b7cb711876595cc1cc2b",
"assets/fonts/MaterialIcons-Regular.otf": "16b0e15ba480ec4d0ffe23b171d5ec11",
"assets/AssetManifest.bin": "fc04066226c45e2be673fb7d39dfe008",
"assets/NOTICES": "73f076943dd7adb1be83a4c5fd609bb3",
"assets/assets/images/placeholder.png": "8f20e5c6af3d824284194fce53dda3a5",
"assets/assets/education_loader.svg": "0b58a0b964c05b3db63c36705a7cddef",
"assets/assets/evaluation_excel.json": "cc54113b10abb3ae8888f5501c3577ae",
"assets/assets/%25C3%25B9evaluation_excel.json": "ec2399c2e4a92833817284156c47d2b1",
"assets/assets/tataouine.gejson": "9538142ffb56ebcd64de926f4ce06a8c",
"assets/assets/data.json": "5cf71dc1c39e070bed3f27990f59d8ad",
"assets/assets/fonts/latin.ttf": "59652e5b9181a30bbcb99466a7e44084",
"assets/assets/fonts/arabic.ttf": "aef6199416a7e451d2d4b39fc4509b30",
"assets/assets/fonts/NotoNaskhArabic-VariableFont_wght.ttf": "a78b9e398865d57423df28857dacdc15",
"assets/assets/test.html": "af1d795aae281b0136655177a613b816",
"assets/assets/tataouine.geojson": "4fe574b38e2adc5c688b355f1e141aff",
"assets/assets/taha.geojson": "ee927bcdec43fd40d3fbf2317deb6ade",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/cigle-meh12.png": "d408ef75ce32b9f943c3f1c63432baf2",
"icons/cigle-meh1.png": "284748a4dc9389c24322b146a734b185",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/cigle-meh.png": "da9d6d292230d24cae0d1c70c6875a69",
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
