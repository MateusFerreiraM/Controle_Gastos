# Controle de Gastos Pessoal & Compartilhado

## Visão Geral do Projeto

Este é um aplicativo multiplataforma de controle financeiro, desenvolvido em **Flutter**, com foco em simplicidade e uso compartilhado. O projeto transforma a experiência de uma planilha de gastos em uma solução móvel, com a vantagem da **sincronização de dados em tempo real** através do Firebase.

O sistema de acesso é baseado em um "código de grupo", permitindo que casais, famílias ou pequenos grupos gerenciem suas finanças de forma colaborativa, privada e segura.

## Funcionalidades Principais

-   **Sincronização em Tempo Real:** Utiliza o Cloud Firestore para que qualquer transação adicionada, editada ou removida em um dispositivo seja refletida instantaneamente nos outros aparelhos do mesmo grupo.
-   **Login por Grupo:** Sistema de autenticação simples que não exige dados pessoais. Usuários se conectam a um "grupo" através de um código único, mantendo seus dados isolados e privados.
-   **Controle de Faturas de Cartão:** Lançamentos no crédito são separados do saldo principal e agrupados em uma aba dedicada de "Faturas", permitindo um controle claro do que está por vencer.
-   **Gerenciamento de Parcelas:** Compras parceladas são automaticamente divididas e lançadas nas faturas dos meses correspondentes.
-   **Gerenciamento Completo (CRUD):** Funcionalidades completas para Adicionar, Ler, Atualizar (com um toque) e Deletar (deslizando) transações, tanto no histórico quanto nas faturas.
-   **Categorias Personalizáveis:** O usuário pode gerenciar suas próprias listas de categorias de Entrada e Saída, incluindo a opção de **apagar todas as transações** para recomeçar o controle.
-   **Saldos Detalhados:** O card principal exibe um resumo claro dos saldos, separando o valor total em "Dinheiro" e "Cartão" (conta bancária).
-   **Interface Intuitiva e Tematizada:** Design limpo com tema, paleta de cores e fontes customizadas para uma experiência de usuário agradável.
-   **Guia Rápido:** Um botão de ajuda (`?`) na tela principal oferece dicas sobre as principais funcionalidades do app a qualquer momento.

## Como Executar

### Pré-requisitos

-   [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado
-   Um editor de código como [VS Code](https://code.visualstudio.com/) ou [Android Studio](https://developer.android.com/studio)
-   Um Emulador Android/iOS configurado ou um dispositivo físico
-   Uma conta gratuita no [Google Firebase](https://firebase.google.com/)

### Instalação

1.  Clone o repositório para sua máquina (substitua pela URL do seu repositório):
    ```bash
    git clone https://github.com/MateusFerreiraM/Controle_Gastos.git
    ```

2.  Acesse a pasta do projeto:
    ```bash
    cd controle_gastos
    ```

3.  Instale as dependências do Flutter:
    ```bash
    flutter pub get
    ```

4.  **Configure o Firebase:**
    * Crie um novo projeto no console do Firebase.
    * Siga as instruções para instalar o FlutterFire CLI e conectar seu app ao seu projeto Firebase com o comando:
        ```bash
        flutterfire configure
        ```
    * Este passo irá gerar o arquivo `lib/firebase_options.dart` com as suas chaves de API. (Lembre-se de adicionar este arquivo ao seu `.gitignore`!).

### Execução

Para iniciar o aplicativo em modo de depuração, conecte um dispositivo ou inicie um emulador e execute:

```bash
flutter run
```

## Gerar a Versão de Lançamento (APK)

Para gerar o arquivo **.apk** que pode ser instalado em dispositivos Android, use o comando:

```bash
flutter build apk
```

O arquivo de saída estará localizado em `build/app/outputs/flutter-apk/app-release.apk.`

## Tecnologias Utilizadas

-   **Framework:** Flutter
-   **Linguagem:** Dart
-   **Backend e Banco de Dados:** Google Firebase (Cloud Firestore)
-   **Persistência Local:** `shared_preferences` (para salvar o código do grupo)
-   **Principais Pacotes:**
    -   `firebase_core`, `cloud_firestore`
    -   `google_fonts` (para a tipografia customizada)
    -   `intl` (para formatação de datas e moedas)


## 📄 Licença

Este projeto está sob a licença MIT.
