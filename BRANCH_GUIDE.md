# 🌳 Guia de Branches - Controle de Gastos

## 📊 Estrutura do Repositório

Este repositório está organizado de forma profissional para manter o histórico completo do desenvolvimento e facilitar futuras contribuições.

### 🏛️ **Branches Principais**

| Branch | Descrição | Status | Uso |
|--------|-----------|--------|-----|
| `main` | 🌟 **Produção** | ✅ Estável | Versão de produção atual (v3.0) |
| `v3.0-firebase-enhanced` | 🚀 **Desenvolvimento v3.0** | ✅ Completa | Branch de desenvolvimento da v3.0 |
| `v2.0-local-development` | 📦 **Versão Local** | ✅ Arquivada | Desenvolvimento com SQLite local |

### 🏷️ **Tags e Releases**

| Tag | Versão | Descrição |
|-----|--------|-----------|
| `v1.0-firebase-original` | v1.0 | Firebase inicial funcionando |
| `firebase-stable-v1.0` | v1.0 | Versão estável Firebase v1.0 |
| `v2.0.0` | v2.0 | Versão local com SQLite |
| `v3.0-firebase-enhanced` | v3.0 | **Versão atual: Firebase + funcionalidades locais** |

## 🔄 **Fluxo de Desenvolvimento**

### **Histórico do Projeto:**

1. **v1.0 (Firebase Original)** 
   - ✅ Funcionalidade básica com Firebase
   - ✅ CRUD de transações
   - ❌ Parou de funcionar

2. **v2.0 (Desenvolvimento Local)**
   - ✅ Migração para SQLite local
   - ✅ Melhorias na interface
   - ✅ Novas funcionalidades
   - ❌ Sem sincronização na nuvem

3. **v3.0 (Firebase Enhanced) - ATUAL**
   - ✅ Retorna ao Firebase
   - ✅ Integra todas as melhorias da v2.0
   - ✅ Sistema de autenticação por PIN
   - ✅ 4 tipos de gráficos profissionais
   - ✅ Validações robustas
   - ✅ Sistema de ajuda interativo

## 🚀 **Para Futuras Contribuições**

### **Branch Principal:**
```bash
git checkout main
git pull origin main
```

### **Nova Feature:**
```bash
git checkout main
git pull origin main
git checkout -b feature/nome-da-feature
# ... desenvolvimento ...
git push origin feature/nome-da-feature
# Criar Pull Request para main
```

### **Hotfix:**
```bash
git checkout main
git checkout -b hotfix/nome-do-fix
# ... correção ...
git push origin hotfix/nome-do-fix
# Criar Pull Request para main
```

### **Release:**
```bash
git checkout main
git tag vX.Y.Z -m "Release vX.Y.Z: Descrição"
git push origin vX.Y.Z
```

## 📋 **Convenções**

### **Nomes de Branches:**
- `feature/nome-da-feature` - Novas funcionalidades
- `hotfix/nome-do-fix` - Correções urgentes
- `bugfix/nome-do-bug` - Correções de bugs
- `release/vX.Y.Z` - Preparação de releases

### **Commits:**
- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Documentação
- `style:` - Formatação
- `refactor:` - Refatoração
- `test:` - Testes
- `chore:` - Manutenção

## 🔐 **Branches Protegidas**

- **main**: Protegida, require Pull Request
- **v3.0-firebase-enhanced**: Histórico preservado
- **v2.0-local-development**: Arquivo histórico

## 📈 **Próximas Versões**

### **v3.1 (Planejada):**
- [ ] Relatórios exportáveis (PDF/Excel)
- [ ] Metas financeiras
- [ ] Notificações push

### **v4.0 (Futuro):**
- [ ] Modo offline completo
- [ ] Múltiplos usuários
- [ ] Dashboard avançado
- [ ] API REST

---

**📝 Nota:** Esta organização preserva todo o histórico de desenvolvimento e facilita a manutenção futura do projeto.