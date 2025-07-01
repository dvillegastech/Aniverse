# Configuración de Cloud Backup para Aniverse

## iCloud (iOS/macOS)

### 1. Configurar iCloud Capabilities en Xcode

1. Abre tu proyecto en Xcode
2. Selecciona el target de tu app
3. Ve a la pestaña "Signing & Capabilities"
4. Haz clic en "+ Capability"
5. Busca y agrega "iCloud"
6. Habilita:
   - Key-value storage
   - iCloud Documents
7. En el Container ID, usa: `iCloud.com.aniverse.app`

### 2. Configurar Info.plist

Agrega las siguientes entradas al archivo `ios/Runner/Info.plist`:

```xml
<key>NSUbiquitousContainers</key>
<dict>
    <key>iCloud.com.aniverse.app</key>
    <dict>
        <key>NSUbiquitousContainerIsDocumentScopePublic</key>
        <true/>
        <key>NSUbiquitousContainerName</key>
        <string>Aniverse</string>
        <key>NSUbiquitousContainerSupportedFolderLevels</key>
        <string>Any</string>
    </dict>
</dict>
```

## Google Drive

### 1. Configurar Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita la API de Google Drive:
   - Ve a "APIs & Services" > "Library"
   - Busca "Google Drive API"
   - Haz clic en "Enable"

### 2. Crear credenciales OAuth 2.0

1. Ve a "APIs & Services" > "Credentials"
2. Haz clic en "Create Credentials" > "OAuth client ID"
3. Configura la pantalla de consentimiento si es necesario
4. Selecciona el tipo de aplicación:
   - Para Android: "Android"
   - Para iOS: "iOS"
   - Para desktop: "Desktop app"

### 3. Configuración por plataforma

#### Android
1. Agrega tu SHA-1 fingerprint
2. Agrega tu package name: `com.aniverse.app`
3. Descarga el archivo `google-services.json`
4. Colócalo en `android/app/`

#### iOS
1. Agrega tu Bundle ID: `com.aniverse.app`
2. Descarga el archivo `GoogleService-Info.plist`
3. Agrégalo a tu proyecto iOS en Xcode

### 4. Configurar el Client ID

En el archivo `lib/services/cloud_backup/google_drive_backup_service.dart`, actualiza el client ID:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: _scopes,
  clientId: 'YOUR_CLIENT_ID_HERE', // Reemplaza con tu Client ID
);
```

## Uso de la funcionalidad

### Primera vez
1. Abre la app
2. Ve a "Más" > "Datos y almacenamiento" > "Crear copia de seguridad"
3. Selecciona tu servicio de cloud preferido (iCloud o Google Drive)
4. Autoriza el acceso cuando se te solicite
5. Activa "Auto Sync" para sincronización automática

### Sincronización automática
- Los backups se sincronizarán automáticamente cada 60 minutos por defecto
- Puedes cambiar el intervalo en la configuración
- La app mantendrá hasta 5 backups en la nube

### Restauración automática
- Al instalar la app en un nuevo dispositivo
- Al iniciar sesión con tu cuenta de cloud
- La app detectará automáticamente los backups existentes
- Se te preguntará si deseas restaurar el backup más reciente

## Notas importantes

- Los backups incluyen toda tu biblioteca, configuraciones y progreso
- Los archivos descargados NO se incluyen en el backup de cloud
- La sincronización requiere conexión a internet
- Los backups están encriptados y son privados para tu cuenta




237761209275-tpuv0spk05fu5nm74a1c70dcm433s3l3.apps.googleusercontent.com