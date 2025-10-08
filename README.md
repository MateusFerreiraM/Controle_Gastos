# Controle de Gastos Pessoal

## Visão Geral do Projeto

Este é um aplicativo de controle financeiro pessoal, desenvolvido em **Flutter**, com foco em simplicidade, segurança e privacidade. O projeto oferece uma solução completa para gerenciamento de finanças pessoais, com **armazenamento local seguro** e **proteção por PIN**.

O aplicativo foi projetado para uso individual, mantendo todos os dados financeiros armazenados localmente no dispositivo usando SQLite, garantindo total privacidade e controle sobre suas informações.

## Funcionalidades Principais

-   **💾 Armazenamento Local Seguro:** Utiliza SQLite para armazenar todas as transações localmente no dispositivo, garantindo privacidade total e funcionamento offline.
-   **🔐 Sistema de Segurança:** Proteção opcional com PIN (4-6 dígitos) criptografado para acesso ao aplicativo.
-   **💳 Controle de Faturas de Cartão:** Lançamentos no crédito são separados do saldo principal e agrupados em uma aba dedicada de "Faturas", permitindo um controle claro do que está por vencer.
-   **📊 Gerenciamento de Parcelas:** Compras parceladas são automaticamente divididas e lançadas nas faturas dos meses correspondentes.
-   **✏️ Gerenciamento Completo (CRUD):** Funcionalidades completas para Adicionar, Ler, Atualizar e Deletar transações, tanto no histórico quanto nas faturas.
-   **📁 Categorias Personalizáveis:** O usuário pode gerenciar suas próprias listas de categorias de Entrada e Saída, com possibilidade de criar, editar e remover categorias conforme necessário.
-   **📈 Análise Gráfica Avançada:** Gráficos horizontais de gastos por categoria, evolução mensal e comparação entre entradas e saídas para análise financeira detalhada.
-   **💰 Saldos Detalhados:** O card principal exibe um resumo claro dos saldos, separando o valor total em "Dinheiro" e "Cartão" (conta bancária).
-   **🇧🇷 Formatação Brasileira:** Suporte completo ao português brasileiro com formatação de moeda em Real (R$) e separador decimal vírgula.
-   **🎨 Interface Intuitiva e Tematizada:** Design limpo com tema personalizado, paleta de cores consistente e tipografia customizada para uma experiência de usuário agradável.
-   **❓ Guia Rápido:** Um botão de ajuda (`?`) na tela principal oferece dicas sobre as principais funcionalidades do app a qualquer momento.

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
-   **Segurança:** crypto (hash SHA-256 para PIN)
-   **Principais Pacotes:**
    -   `sqflite ^2.3.0` (banco de dados local SQLite)
    -   `shared_preferences ^2.5.3` (configurações e preferências)
    -   `crypto ^3.0.6` (criptografia para PINs)
    -   `fl_chart ^1.1.0` (gráficos e análises financeiras)
    -   `google_fonts ^6.3.1` (tipografia customizada)
    -   `intl ^0.20.2` (formatação de datas e moedas brasileiras)

## Funcionalidades de Segurança

O aplicativo oferece proteção opcional através de:

-   **🔐 PIN de 4-6 dígitos:** Senha numérica criptografada com SHA-256
-   **🛡️ Sistema de Bloqueio:** Proteção contra tentativas excessivas de acesso (5 tentativas + 15 minutos de bloqueio)
-   **⚙️ Configuração Flexível:** Usuário pode ativar/desativar segurança conforme necessário
-   **💽 Armazenamento Local:** Todos os dados ficam apenas no seu dispositivo

## Estrutura do Projeto

```
lib/
├── pages/              # Telas principais do aplicativo
│   ├── pagina_inicial.dart         # Tela principal com resumo financeiro
│   ├── tela_autenticacao.dart      # Tela de autenticação por PIN
│   ├── tela_categorias.dart        # Gerenciamento de categorias
│   ├── tela_configuracao_seguranca.dart # Configurações de segurança
│   └── tela_graficos.dart          # Análises e gráficos
├── services/           # Serviços do aplicativo
│   ├── auth_service.dart           # Serviço de autenticação
│   └── database_service.dart       # Serviço de banco de dados SQLite
├── widgets/            # Componentes reutilizáveis
│   ├── auth_wrapper.dart           # Wrapper de autenticação
│   └── formulario_transacao.dart   # Formulário de transações
├── app_colors.dart     # Paleta de cores personalizada
├── app_config.dart     # Configurações globais
└── main.dart           # Ponto de entrada do aplicativo
```

## 🚀 Histórico de Desenvolvimento

### Migração Completa (Outubro 2025)
- ✅ **Migração de Firebase para SQLite:** Transição completa para armazenamento local
- ✅ **Remoção de Códigos de Grupo:** Simplificação para uso individual
- ✅ **Sistema de Segurança:** Implementação de autenticação por PIN
- ✅ **Otimização de Performance:** Melhoria na velocidade e responsividade
- ✅ **Compatibilidade Universal:** Funcionamento garantido em todos os dispositivos Android

## � Instalação do APK

### Download Direto
O APK de release está disponível em: `build/app/outputs/flutter-apk/app-release.apk`

### Instalação no Android
1. **Habilite "Fontes Desconhecidas"** nas configurações do Android
2. **Transfira o APK** para o dispositivo Android
3. **Abra o arquivo APK** e confirme a instalação
4. **Configure um PIN** na primeira execução (opcional)

### Requisitos Mínimos
- **Android:** Versão 5.0 (API level 21) ou superior
- **Armazenamento:** ~15MB livres
- **Permissões:** Apenas armazenamento local (sem acesso à internet)

## �📄 Licença

Este projeto está sob a licença MIT. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🤝 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para:

-   🐛 Reportar bugs
-   💡 Sugerir novas funcionalidades  
-   🔧 Enviar pull requests
-   📚 Melhorar a documentação

### Como Contribuir
1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📧 Contato

**Desenvolvido por:** Mateus Ferreira Machado
**GitHub:** [@MateusFerreiraM](https://github.com/MateusFerreiraM)

---

⭐ Se este projeto foi útil para você, considere dar uma estrela no repositório!

💡 **Dica:** Este aplicativo é ideal para quem busca controle financeiro pessoal com total privacidade e sem dependência de internet!
