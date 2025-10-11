# 💰 Controle de Gastos Pessoal

## 📱 Sobre o Projeto

Este é um aplicativo de controle financeiro pessoal, desenvolvido em **Flutter**, que permite o gerenciamento completo de despesas e receitas de forma simples e compartilhada. O projeto nasceu da necessidade de substituir uma planilha de controle, trazendo a funcionalidade para a palma da mão com a vantagem da **sincronização em tempo real** entre múltiplos dispositivos.

O app utiliza o **Firebase (Cloud Firestore)** como backend, garantindo que os dados estejam sempre atualizados na nuvem. O sistema de acesso é baseado em autenticação por **PIN seguro** e "código de grupo", permitindo que casais ou famílias compartilhem o mesmo controle financeiro de forma privada e segura.

🔗 **Repositório:** `https://github.com/MateusFerreiraM/Controle_Gastos.git`

## ✨ Funcionalidades Principais

### 🔐 **Segurança e Autenticação**
- **Autenticação por PIN:** Sistema seguro com criptografia SHA-256
- **Primeiro Acesso Guiado:** Configuração inicial intuitiva
- **Recuperação de PIN:** Opção de reset em caso de esquecimento
- **Dados Criptografados:** Todas as informações sensíveis são protegidas

### 💳 **Gerenciamento de Transações**
- **CRUD Completo:** Criar, ler, editar e excluir transações
- **Tipos de Transação:** Entradas (receitas) e Saídas (despesas)
- **Métodos de Pagamento:** Dinheiro, Cartão de Débito, Cartão de Crédito
- **Sistema de Parcelas:** Compras parceladas no cartão de crédito (1-48x)
- **Validação Inteligente:** Sistema robusto de validação com alertas específicos
- **Observações Detalhadas:** Campo livre para anotações importantes

### 📊 **Análise Financeira Avançada**
- **4 Tipos de Gráficos Profissionais:**
  - 📈 **Resumo Financeiro:** Cards com totais consolidados
  - 🥧 **Gastos por Categoria:** Gráfico de barra com percentuais
  - 📉 **Evolução Mensal:** Gráfico de linha temporal
  - 📊 **Comparação Entrada vs Saída:** Gráfico de barras comparativo
- **Análise em Tempo Real:** Dados sempre atualizados
- **Visualização Interativa:** Interface rica e responsiva

### 🏷️ **Sistema de Categorias**
- **Categorias Personalizáveis:** Crie e gerencie suas próprias categorias
- **Separação por Tipo:** Categorias distintas para entradas e saídas
- **Organização Inteligente:** Filtros automáticos baseados no tipo de transação

### 🌐 **Sincronização e Compartilhamento**
- **Sincronização em Tempo Real:** Firebase Cloud Firestore
- **Multi-dispositivo:** Acesse de qualquer lugar
- **Grupos Familiares:** Compartilhe controle financeiro com segurança
- **Dados na Nuvem:** Backup automático e recuperação

### 🎨 **Interface e Experiência**
- **Design Material:** Interface moderna e intuitiva
- **Tema Personalizado:** Cores consistentes e profissionais
- **Sistema de Ajuda Integrado:** 
  - ❓ **Ícone de Ajuda Interativo:** Guias contextuais em cada tela
  - 📖 **Tutoriais Organizados:** Instruções claras e exemplos práticos
  - 💡 **Dicas Inteligentes:** Orientações para melhor uso do app
- **Responsivo:** Funciona perfeitamente em diferentes tamanhos de tela
- **Feedback Visual:** Animações e indicadores de status

### ⚙️ **Configurações Avançadas**
- **Gerenciamento de PIN:** Alteração segura de senha
- **Configuração de Categorias:** Interface dedicada para organização
- **Reset de Dados:** Opção de limpeza completa com confirmação
- **Menu de Configurações:** Acesso centralizado a todas as opções

## 🚀 Como Executar

### 📋 Pré-requisitos

-   [Flutter SDK](https://docs.flutter.dev/get-started/install) (versão 3.0 ou superior)
-   Editor: [VS Code](https://code.visualstudio.com/) ou [Android Studio](https://developer.android.com/studio)
-   Emulador Android/iOS ou dispositivo físico
-   Conta gratuita no [Google Firebase](https://firebase.google.com/)

### 🔧 Instalação

1. **Clone o repositório:**
    ```bash
    git clone https://github.com/MateusFerreiraM/Controle_Gastos.git
    cd Controle_Gastos
    ```

2. **Instale as dependências:**
    ```bash
    flutter pub get
    ```

3. **Configure o Firebase:**
    ```bash
    # Instale o FlutterFire CLI
    dart pub global activate flutterfire_cli
    
    # Configure o projeto
    flutterfire configure
    ```
    > ⚠️ **Importante:** Adicione `lib/firebase_options.dart` ao `.gitignore`

4. **Configurar regras do Firestore:**
    ```javascript
    // Regras de segurança no console do Firebase
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        match /grupos/{groupId} {
          allow read, write: if request.auth != null;
          match /transacoes/{document} {
            allow read, write: if request.auth != null;
          }
        }
      }
    }
    ```

### ▶️ Execução

```bash
# Modo desenvolvimento
flutter run

# Modo release (Android)
flutter build apk --release
```

## 🛠️ Tecnologias Utilizadas

### **Core**
- **Framework:** Flutter 3.x
- **Linguagem:** Dart 3.x
- **Estado:** StatefulWidget nativo

### **Backend e Dados**
- **Firebase Core:** Configuração base
- **Cloud Firestore:** Banco de dados NoSQL
- **Criptografia:** SHA-256 para PINs
- **Persistência Local:** SharedPreferences

### **Interface e Gráficos**
- **FL Chart:** Biblioteca de gráficos profissionais
- **Google Fonts:** Tipografia customizada
- **Material Design:** Sistema de design do Google

### **Utilitários**
- **Intl:** Formatação de datas e moedas (pt_BR)
- **Crypto:** Criptografia e hash
- **Path Provider:** Gerenciamento de arquivos

### **Dependências Principais**
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  shared_preferences: ^2.2.2
  crypto: ^3.0.3
  google_fonts: ^6.1.0
  intl: ^0.19.0
  fl_chart: ^0.66.0
```

## 🤝 Contribuindo

1. **Fork** o projeto
2. Crie uma **branch** para sua feature (`git checkout -b feature/MinhaFeature`)
3. **Commit** suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. **Push** para a branch (`git push origin feature/MinhaFeature`)
5. Abra um **Pull Request**

## 📄 Licença

Este projeto está sob a licença **MIT**. Veja o arquivo `LICENSE` para mais detalhes.

## 👨‍💻 Autor

**Mateus Ferreira**
- GitHub: [@MateusFerreiraM](https://github.com/MateusFerreiraM)
- LinkedIn: [Mateus Ferreira](https://www.linkedin.com/in/mateusferreiramachado)

---

⭐ **Se este projeto foi útil para você, considere dar uma estrela no repositório!**
