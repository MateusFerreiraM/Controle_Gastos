# Controle de Gastos Pessoal

## Visão Geral do Projeto

Este é um aplicativo de controle financeiro pessoal, desenvolvido em **Flutter**, com foco em simplicidade, segurança e privacidade. O projeto oferece uma solução completa para gerenciamento de finanças pessoais, com **armazenamento local seguro** e **proteção por biometria e PIN**.

O aplicativo foi projetado para uso individual, mantendo todos os dados financeiros armazenados localmente no dispositivo, garantindo total privacidade e controle sobre suas informações.

## Funcionalidades Principais

-   **Armazenamento Local Seguro:** Utiliza SQLite para armazenar todas as transações localmente no dispositivo, garantindo privacidade total e funcionamento offline.
-   **Sistema de Segurança Avançado:** Proteção opcional com PIN e autenticação biométrica (impressão digital, reconhecimento facial) para acesso ao aplicativo.
-   **Controle de Faturas de Cartão:** Lançamentos no crédito são separados do saldo principal e agrupados em uma aba dedicada de "Faturas", permitindo um controle claro do que está por vencer.
-   **Gerenciamento de Parcelas:** Compras parceladas são automaticamente divididas e lançadas nas faturas dos meses correspondentes.
-   **Gerenciamento Completo (CRUD):** Funcionalidades completas para Adicionar, Ler, Atualizar e Deletar transações, tanto no histórico quanto nas faturas.
-   **Categorias Personalizáveis:** O usuário pode gerenciar suas próprias listas de categorias de Entrada e Saída, com possibilidade de criar, editar e remover categorias conforme necessário.
-   **Análise Gráfica Avançada:** Gráficos horizontais de gastos por categoria, evolução mensal e comparação entre entradas e saídas para análise financeira detalhada.
-   **Saldos Detalhados:** O card principal exibe um resumo claro dos saldos, separando o valor total em "Dinheiro" e "Cartão" (conta bancária).
-   **Formatação Brasileira:** Suporte completo ao português brasileiro com formatação de moeda em Real (R$) e separador decimal vírgula.
-   **Interface Intuitiva e Tematizada:** Design limpo com tema personalizado, paleta de cores consistente e tipografia customizada para uma experiência de usuário agradável.
-   **Guia Rápido:** Um botão de ajuda (`?`) na tela principal oferece dicas sobre as principais funcionalidades do app a qualquer momento.

## Como Executar

### Pré-requisitos

-   **Flutter SDK:** Versão 3.0 ou superior
-   **Dart SDK:** Versão 3.0 ou superior  
-   **Android Studio** ou **VS Code** com plugins do Flutter
-   **Dispositivo Android/iOS** ou **Emulador** configurado

### Configuração

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/MateusFerreiraM/Controle_Gastos.git
   cd Controle_Gastos
   ```

2. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

3. **Configure o dispositivo:**
   - Conecte um dispositivo físico via USB com depuração habilitada
   - OU inicie um emulador Android/iOS

### Execução

Para iniciar o aplicativo em modo de depuração:
```bash
flutter run
```

## Gerar a Versão de Lançamento (APK)

Para gerar o arquivo **.apk** que pode ser instalado em dispositivos Android:
```bash
flutter build apk --release
```
O arquivo de saída estará localizado em `build/app/outputs/flutter-apk/app-release.apk`

## Tecnologias Utilizadas

-   **Framework:** Flutter
-   **Linguagem:** Dart  
-   **Banco de Dados Local:** SQLite (sqflite)
-   **Armazenamento de Preferências:** shared_preferences
-   **Segurança:** local_auth (biometria) + crypto (hash SHA-256)
-   **Principais Pacotes:**
    -   `sqflite` (banco de dados local SQLite)
    -   `shared_preferences` (configurações e preferências)
    -   `local_auth` (autenticação biométrica) 
    -   `crypto` (criptografia para PINs)
    -   `fl_chart` (gráficos e análises financeiras)
    -   `google_fonts` (tipografia customizada)
    -   `intl` (formatação de datas e moedas brasileiras)

## Funcionalidades de Segurança

O aplicativo oferece proteção opcional através de:

-   **PIN de 4-6 dígitos:** Senha numérica criptografada com SHA-256
-   **Autenticação Biométrica:** Impressão digital, reconhecimento facial ou íris (quando disponível no dispositivo)
-   **Sistema de Bloqueio:** Proteção contra tentativas excessivas de acesso
-   **Configuração Flexível:** Usuário pode ativar/desativar segurança conforme necessário

## Estrutura do Projeto

```
lib/
├── pages/           # Telas principais do aplicativo
├── services/        # Serviços (database, autenticação)  
├── widgets/         # Componentes reutilizáveis
├── app_colors.dart  # Paleta de cores personalizada
├── app_config.dart  # Configurações globais
└── main.dart        # Ponto de entrada do aplicativo
```

## 📄 Licença

Este projeto está sob a licença MIT. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🤝 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para:

-   Reportar bugs
-   Sugerir novas funcionalidades  
-   Enviar pull requests
-   Melhorar a documentação

## 📧 Contato

**Desenvolvido por:** Mateus Ferreira Machado

---

⭐ Se este projeto foi útil para você, considere dar uma estrela no repositório!
