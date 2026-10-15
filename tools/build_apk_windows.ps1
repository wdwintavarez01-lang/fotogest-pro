param(
    [string]$VersionName = '1.1.0',
    [int]$VersionCode = 3
)

$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$previousJavaOptions = $env:JAVA_TOOL_OPTIONS
$previousDirectory = Get-Location

# En algunos procesos Windows, el selector NIO de Java puede crear un socket
# AF_UNIX pero no conectarse a el. Una ruta inexistente hace que OpenJDK use
# su alternativa TCP local. La opcion solo afecta este proceso y sus hijos.
$unavailableSocketDirectory = Join-Path $env:SystemDrive 'FotoGest_NIO_AF_UNIX_NoDisponible'
if (Test-Path -LiteralPath $unavailableSocketDirectory) {
    throw "La ruta de alternativa NIO debe permanecer inexistente: $unavailableSocketDirectory"
}

try {
    $nioOption = "-Djdk.net.unixdomain.tmpdir=$unavailableSocketDirectory"
    $env:JAVA_TOOL_OPTIONS = (($previousJavaOptions, $nioOption) | Where-Object { $_ }) -join ' '
    Set-Location -LiteralPath $projectDirectory
    # Flutter regenera el registro de plugins en modo release y excluye
    # integration_test, que solo debe formar parte de la APK de pruebas.
    & flutter build apk --release "--build-name=$VersionName" "--build-number=$VersionCode"
    $buildExitCode = $LASTEXITCODE
    if ($buildExitCode -ne 0) {
        throw "La compilacion de Flutter termino con codigo $buildExitCode."
    }
    $apkPath = Join-Path $projectDirectory 'build\app\outputs\flutter-apk\app-release.apk'
    Get-FileHash -LiteralPath $apkPath -Algorithm SHA256
} finally {
    $env:JAVA_TOOL_OPTIONS = $previousJavaOptions
    Set-Location -LiteralPath $previousDirectory.Path
}
