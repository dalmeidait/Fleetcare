# 🚗 FleetCare - Sistema de Gestão de Frotas e Oficinas

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![NodeJS](https://img.shields.io/badge/node.js-6DA55F?style=for-the-badge&logo=node.js&logoColor=white)
![NestJS](https://img.shields.io/badge/nestjs-%23E0234E.svg?style=for-the-badge&logo=nestjs&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

O **FleetCare** é um sistema completo e multiplataforma (Mobile e Web) desenvolvido para revolucionar a gestão de frotas e oficinas mecânicas. Ele centraliza o cadastro de clientes, veículos e o controle de Ordens de Serviço (OS), eliminando o uso de papel e garantindo que todas as informações fiquem sincronizadas em tempo real.

---

## ✨ Funcionalidades Principais

- 👥 **Gestão de Clientes:** Cadastro rápido e eficiente de proprietários e empresas.
- 🚘 **Gestão de Veículos:** Controle detalhado da frota, com vinculação direta aos seus respectivos donos.
- 📋 **Ordens de Serviço (OS):** O coração do sistema. Abertura de OS integrando cliente, veículo, serviços realizados, peças e cálculo automático de valores.
- 🔄 **Sincronização em Tempo Real:** O que o mecânico atualiza no pátio pelo celular, o gerente vê no escritório pelo computador na mesma hora.

---

## 🛠️ Tecnologias Utilizadas

O projeto foi construído utilizando uma arquitetura moderna dividida em duas partes (Monorepo):

### Frontend (Aplicativo Mobile & Web)
* **[Flutter](https://flutter.dev/):** Framework principal para a criação da interface multiplataforma.
* **Dart:** Linguagem de programação base do Flutter.
* **HTTP & Shared Preferences:** Para comunicação com a API e armazenamento local de tokens de sessão.

### Backend (Servidor & API)
* **[Node.js](https://nodejs.org/):** Ambiente de execução do servidor.
* **[NestJS](https://nestjs.com/):** Framework progressivo para construir aplicações backend eficientes, confiáveis e escaláveis.

