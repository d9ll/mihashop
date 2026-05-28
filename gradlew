name: Build & Release Android APK

on:
  push:
    tags:
      - 'v*' # Сработает автоматически, когда ты создашь тег версии (например, v1.3, v1.4)
  workflow_dispatch: # Позволяет запускать сборку вручную кнопкой через вкладку Actions

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Code
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'
        cache: gradle

    - name: Find and Grant execute permission for gradlew
      run: |
        GRADLEW_PATH=$(find . -name "gradlew" | head -n 1)
        if [ -z "$GRADLEW_PATH" ]; then
          echo "Критическая ошибка: файл gradlew вообще не найден в репозитории!"
          exit 1
        fi
        echo "Файл gradlew найден по пути: $GRADLEW_PATH"
        
        # Принудительно лечим виндовые концы строк (CRLF -> LF) прямо в облаке
        sed -i 's/\r$//' "$GRADLEW_PATH"
        
        chmod +x "$GRADLEW_PATH"
        echo "GRADLEW_DIR=$(dirname "$GRADLEW_PATH")" >> $GITHUB_ENV

    - name: Build Release APK
      run: |
        cd ${{ env.GRADLEW_DIR }}
        ./gradlew assembleRelease

    - name: Create GitHub Release
      uses: softprops/action-gh-release@v2
      with:
        files: |
          **/build/outputs/apk/release/*-unsigned.apk
          **/build/outputs/apk/release/*.apk
        name: Release ${{ github.ref_name }}
        tag_name: ${{ github.ref }}
        draft: false
        prerelease: false
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}