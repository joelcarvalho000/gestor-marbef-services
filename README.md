# Gestor Marbef Services — versão 0.3 (interface Android)

Esta versão inicial contém o ecrã de abertura, login demonstrativo e painel principal com as cores extraídas visualmente do logótipo enviado (azul, vermelho e branco).

## Importante
- É código-fonte Flutter, não é ainda um APK instalável.
- O login é apenas visual/demonstrativo: ainda não valida utilizadores nem palavras-passe.
- Os cartões apresentam valores de exemplo a zero.
- Os módulos do painel são atalhos de interface; vendas, stock, clientes, sincronização e permissões ainda precisam de implementação e testes.
- A base de dados local, sincronização na nuvem, impressão e segurança de produção não estão incluídas nesta versão.

## Gerar o projecto Android
1. Instalar Flutter e Android Studio num computador.
2. Extrair este ZIP para uma pasta, por exemplo `C:\gestor_marbef_v03`.
3. Abrir PowerShell nessa pasta e executar:
   `flutter create --platforms=android .`
   `flutter pub get`
   `flutter run`
4. Para gerar APK de teste:
   `flutter build apk --release`
5. O APK será criado em `build\app\outputs\flutter-apk\app-release.apk`.

## Identidade visual
O ficheiro original do logótipo fornecido está em `assets/images/marbef_logo.jpg`.
