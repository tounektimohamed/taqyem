'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"manifest.json": "3fc29f9294b755bca0378065b89e216e",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"canvaskit/canvaskit.js": "738255d00768497e86aa4ca510cce1e1",
"canvaskit/skwasm.js.symbols": "c3c05bd50bdf59da8626bbe446ce65a3",
"canvaskit/canvaskit.wasm": "9251bb81ae8464c4df3b072f84aa969b",
"canvaskit/skwasm.js": "5d4f9263ec93efeb022bb14a3881d240",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"canvaskit/skwasm.wasm": "4051bfc27ba29bf420d17aa0c3a98bce",
"canvaskit/chromium/canvaskit.js": "901bb9e28fac643b7da75ecfd3339f3f",
"canvaskit/chromium/canvaskit.wasm": "399e2344480862e2dfa26f12fa5891d7",
"canvaskit/chromium/canvaskit.js.symbols": "ee7e331f7f5bbf5ec937737542112372",
"canvaskit/canvaskit.js.symbols": "74a84c23f5ada42fe063514c587968c6",
"main.dart.js": "178ff38d61b5c825abc6c8f57c5f1f28",
"assets/AssetManifest.bin.json": "b265c31e2f9f0134143b79c98579dd24",
"assets/AssetManifest.json": "7b92530ae7b56f3747a3fb0838160da2",
"assets/AssetManifest.bin": "1db3670e8ef720d8375fc8da958501db",
"assets/packages/day_night_time_picker/assets/sun.png": "5fd1657bcb73ce5faafde4183b3dab22",
"assets/packages/day_night_time_picker/assets/moon.png": "71137650ab728a466a50fa4fa78fb2b9",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "1b5634953f2674404ac41a77135a0357",
"assets/packages/alarm/assets/long_blank.mp3": "d632dd58e2137a2e67849c108d5eb4b6",
"assets/packages/alarm/assets/not_blank.mp3": "71ac239a121767241ccfcc1b625d44e7",
"assets/packages/floating_snackbar/assets/image/flutter_02.png": "6aa8464adbaf2dc20a6e34f2695a61fc",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "f3307f62ddff94d2cd8b103daf8d1b0f",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "87d86c3427953ab8467786c58064f462",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "eafdfd1fe143602951db6ff91b4e5b4e",
"assets/NOTICES": "577295d49e0afbf540baedecd5ead867",
"assets/fonts/MaterialIcons-Regular.otf": "a968afa1178d09f2add4f05bf4b0f381",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/FontManifest.json": "5a32d4310a6f5d9a6b651e75ba0d7372",
"assets/lib/assets/icon_small.png": "74628b6f07bba4b2c4ee92f259c44afb",
"assets/lib/assets/icons/foam.png": "09a259213b671ae9f3b8bf3b5a78f753",
"assets/lib/assets/icons/emergency-call.gif": "1c4af35aa81f8ac9c33ba45867ea7403",
"assets/lib/assets/icons/4.gif": "d27e6c384374264888d8a269e6aea70c",
"assets/lib/assets/icons/nasalspray.gif": "966bb817238fa005383aee2d9e871558",
"assets/lib/assets/icons/lotion.gif": "92e0824f9f303071b312b5d73b6a1207",
"assets/lib/assets/icons/inhalator.png": "26fd1da648b7f7c9957ed869e7cc8da5",
"assets/lib/assets/icons/herbal.png": "8d7e36300a652afc0a42599a4854c952",
"assets/lib/assets/icons/more.gif": "34614821da9e5dca593852b83d1c3ea7",
"assets/lib/assets/icons/no_reminders.gif": "d63d0060458b46c32b1a1755773c3af3",
"assets/lib/assets/icons/no_alarm.gif": "43a8865a9c982001266a4ebc1c8e151a",
"assets/lib/assets/icons/cream.png": "22cf3e79cd081315aee24c65327b6ab2",
"assets/lib/assets/icons/lotion.png": "ec1f4b488ced49c76a936f9838fbc72b",
"assets/lib/assets/icons/cream.gif": "66988dd928e27ff892309294c1c359b0",
"assets/lib/assets/icons/suppository.png": "818aa1accd43889ebff3280f660b6a86",
"assets/lib/assets/icons/spray.gif": "dc33a507c5f41221c863ca2635cbd5aa",
"assets/lib/assets/icons/medicine.png": "d4ea517821e3d6d676e9755e8730095e",
"assets/lib/assets/icons/pill.gif": "45add6d130083cb038cf83b866c18025",
"assets/lib/assets/icons/spray.png": "bc90dca5371ab3add98e237a344d40f7",
"assets/lib/assets/icons/pills.png": "1cf79c3a5cad564a53c94b4b9bfe1b8c",
"assets/lib/assets/icons/heartbeat.gif": "22de0032d3cd5da8e63655eafe84464b",
"assets/lib/assets/icons/tablet.gif": "983e6634923143be441af8d6107191d2",
"assets/lib/assets/icons/powder.gif": "78005e5c4e9f820c739d587fb881bfa3",
"assets/lib/assets/icons/pills.gif": "b9a50958440eac7fd7ce6350f438fa82",
"assets/lib/assets/icons/tube.png": "cbafa2ee32c87be9ddd31109f05c602d",
"assets/lib/assets/icons/inhalator.gif": "a02bfd110fec33a42509c2e917480ccd",
"assets/lib/assets/icons/patch.png": "81f177fc085be50806357b2f05022853",
"assets/lib/assets/icons/tablet.png": "95726e4a0c2e1e0d9e37e60ef3ef4d85",
"assets/lib/assets/icons/image-.gif": "20b4472c2dc158dbdcf8bc85fde7f038",
"assets/lib/assets/icons/powder.png": "884b4066cfc0ca72c87fd33093647f85",
"assets/lib/assets/icons/patch.gif": "02bcee7407ddfbf0784acb0099db66b9",
"assets/lib/assets/icons/height.gif": "d1ff2d2c6b705b168dd9764e23ccf2b5",
"assets/lib/assets/icons/nutrients.png": "67c8fb18591e40cdfee8e12140aefbc8",
"assets/lib/assets/icons/pill.png": "9b0ad477c40df8fd53f72d27e6213997",
"assets/lib/assets/icons/nasalspray.png": "98a56530be42a46beb7d712ebf4cc4d8",
"assets/lib/assets/icons/foam.gif": "ee5d1a193dba5ad1eb6abf21c109e93e",
"assets/lib/assets/icons/syringe.gif": "9e2fb51a5041e59511af398bc66a0395",
"assets/lib/assets/icons/1.gif": "b9f37e61dab7f88ce4f0eb16aa7526d5",
"assets/lib/assets/icons/nutrients.gif": "1b5225e795058823974ffbfad76030b5",
"assets/lib/assets/icons/liquid.gif": "e6e1045f48c6feb00cb6e46bee42ad4f",
"assets/lib/assets/icons/herbal.gif": "1c6aaf2f77e63eed800ad95562c52963",
"assets/lib/assets/icons/pills%2520(1).gif": "843cf8919378c6df6c0f7c2fa3003a0a",
"assets/lib/assets/icons/tube.gif": "716790a0f2270844cc8c8b6978be433e",
"assets/lib/assets/icons/drops.png": "d80b56f6e82307cfff2c9e33205509ff",
"assets/lib/assets/icons/drops.gif": "fe178c79ad7e7cf7767d1d819292104a",
"assets/lib/assets/icons/syringe.png": "6e08d0c80d5fba9e11db24455387458f",
"assets/lib/assets/icons/weight-scale.gif": "6a56e40131a69cb322fda14f9d5d0a51",
"assets/lib/assets/icons/me/admin2.gif": "d17ff9937581a75cf33711d056343596",
"assets/lib/assets/icons/me/maps.gif": "8069fd3e8e3a641261e2dc50b59531ba",
"assets/lib/assets/icons/me/service.gif": "db0227f67927da081a0f7c5a4d095c1a",
"assets/lib/assets/icons/me/admin1.gif": "ce48ed5b8c4038a0d9712b1c35b11779",
"assets/lib/assets/icons/me/logo.png": "963f2210655c1cb3018c395cf45f6872",
"assets/lib/assets/icons/me/admin3.gif": "00af01fc0b1e3d819779c347789ee8d4",
"assets/lib/assets/icons/me/admin4.gif": "e89657199c53d1f05d5c46b2353dcc3f",
"assets/lib/assets/icons/suppository.gif": "9d84aca884fb3cf6ef671f735dbe8dff",
"assets/lib/assets/icons/liquid.png": "cf6450d222a9d6f21f19dd4b5e967ef6",
"assets/lib/assets/icons/2.gif": "34614821da9e5dca593852b83d1c3ea7",
"assets/lib/assets/icons/3.gif": "475ad8ed32c71a9329ff178bde980216",
"assets/lib/assets/icon.png": "765d583e91091f70da0a5a9b081805bc",
"assets/lib/assets/images/medication.gif": "028c15c6b9d659664791b26d063731a8",
"assets/lib/assets/images/ambulance.png": "cd030288e1f17d355911c8c075418c50",
"assets/lib/assets/images/bell.png": "5f9989695d04881b2075502aac8aa796",
"assets/lib/assets/images/taking_med.png": "d57977f40ce0a001ac011aacd79b5452",
"assets/lib/assets/user.png": "6620d99d7d02e89a5c379af73293d794",
"assets/lib/l10n/app_si.arb": "961d8e654a771f35688e3c25d15dc326",
"assets/lib/l10n/app_en.arb": "199bcea5bf4f6ecb2901a39665f2325a",
"flutter_bootstrap.js": "2fee3cb47c94377fb7ba64a04766bdd8",
"version.json": "e705f5375e538c89ae22742e203f00dc",
"index.html": "d37e2be822ebde4e61359b76b81740e5",
"/": "d37e2be822ebde4e61359b76b81740e5",
"flutter.js": "383e55f7f3cce5be08fcf1f3881f585c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796"};
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
