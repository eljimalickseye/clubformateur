export const environment = {
  production: false,
  apiUrl: 'http://127.0.0.1:8000/api/v1',
  firebase: {
    apiKey: 'AIzaSyDslsyYXqMbUsKIuDZTTYcpwDWsm_mJw_w',
    authDomain: 'anour-84a69.firebaseapp.com',
    projectId: 'anour-84a69',
    storageBucket: 'anour-84a69.firebasestorage.app',
    messagingSenderId: '501861569061',
    appId: '1:501861569061:web:587c13ee3d9f633c98a5cc',
    measurementId: 'G-KGWKTRG11V',
    databaseURL: 'https://anour-84a69-default-rtdb.firebaseio.com',
  },
  cloudinary: {
    cloudName: 'YOUR_CLOUD_NAME',
    uploadPreset: 'anour_videos',
    apiKey: 'YOUR_CLOUDINARY_KEY',
  },
  livekit: {
    serverUrl: 'wss://anour-rv83fs3g.livekit.cloud',
    apiKey: 'APIsCo9dSx9D6VC',
    apiSecret: 'uOfP2sDQQjFe3dREQazqQq3fLWkv5JPfMVnikLAoCPAB',
  },
  intech: {
    apiKey: '9D65FC1C-BA2D-4102-BFC5-F0D348277999',
    apiUrl: 'https://api.intech.sn/api-services',
    payUrl: 'https://api.intech.sn/api-services/operation',
    statusUrl: 'https://api.intech.sn/api-services/get-transaction-status',
    waveServiceCode: 'WAVE_SN_API_CASH_OUT',
    orangeServiceCode: 'ORANGE_SN_API_CASH_OUT',
  },
  emulators: {
    enabled: false,
    authPort: 9099,
    firestorePort: 8080,
    storagePort: 9199,
    functionsPort: 5001,
  },
};
