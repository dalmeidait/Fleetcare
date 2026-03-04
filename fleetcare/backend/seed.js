const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const count = await prisma.servico.count();
    if (count < 90) {
        console.log('Clearing old items...');
        await prisma.itemServicoOS.deleteMany();
        await prisma.itemPecaOS.deleteMany();
        await prisma.servico.deleteMany();
        await prisma.peca.deleteMany();

        console.log('Seeding new services...');
        await prisma.servico.createMany({
            data: [
                { descricao: 'Troca de óleo', preco: 120.00 }, { descricao: 'Troca de filtro de óleo', preco: 60.00 }, { descricao: 'Troca de filtro de ar', preco: 50.00 }, { descricao: 'Troca de filtro de combustível', preco: 80.00 }, { descricao: 'Troca de filtro de cabine', preco: 60.00 }, { descricao: 'Revisão básica', preco: 180.00 }, { descricao: 'Revisão intermediária', preco: 350.00 }, { descricao: 'Revisão completa', preco: 600.00 }, { descricao: 'Verificação de níveis', preco: 50.00 }, { descricao: 'Lubrificação geral', preco: 90.00 },
                { descricao: 'Alinhamento', preco: 120.00 }, { descricao: 'Balanceamento', preco: 100.00 }, { descricao: 'Alinhamento + balanceamento', preco: 200.00 }, { descricao: 'Troca de amortecedor', preco: 300.00 }, { descricao: 'Troca de mola', preco: 280.00 }, { descricao: 'Troca de pivô', preco: 150.00 }, { descricao: 'Troca de bandeja', preco: 220.00 }, { descricao: 'Troca de terminal de direção', preco: 140.00 }, { descricao: 'Verificação de suspensão', preco: 100.00 }, { descricao: 'Ajuste de caixa de direção', preco: 180.00 },
                { descricao: 'Troca de pastilhas', preco: 180.00 }, { descricao: 'Troca de discos', preco: 250.00 }, { descricao: 'Retífica de discos', preco: 160.00 }, { descricao: 'Troca de fluido de freio', preco: 120.00 }, { descricao: 'Revisão do sistema de freios', preco: 150.00 }, { descricao: 'Troca de cilindro mestre', preco: 280.00 }, { descricao: 'Troca de servo-freio', preco: 350.00 }, { descricao: 'Ajuste de freio traseiro', preco: 90.00 }, { descricao: 'Verificação ABS', preco: 120.00 }, { descricao: 'Troca de lonas', preco: 200.00 },
                { descricao: 'Diagnóstico eletrônico', preco: 150.00 }, { descricao: 'Troca de bateria', preco: 80.00 }, { descricao: 'Teste de bateria', preco: 50.00 }, { descricao: 'Troca de alternador', preco: 300.00 }, { descricao: 'Troca de motor de partida', preco: 280.00 }, { descricao: 'Reparação elétrica simples', preco: 120.00 }, { descricao: 'Reparação elétrica complexa', preco: 350.00 }, { descricao: 'Troca de lâmpadas', preco: 60.00 }, { descricao: 'Ajuste de faróis', preco: 80.00 }, { descricao: 'Reset de módulos', preco: 100.00 },
                { descricao: 'Troca de líquido de arrefecimento', preco: 150.00 }, { descricao: 'Limpeza do sistema', preco: 200.00 }, { descricao: 'Troca de radiador', preco: 350.00 }, { descricao: 'Troca de válvula termostática', preco: 180.00 }, { descricao: 'Troca de mangueiras', preco: 120.00 }, { descricao: 'Carga de ar-condicionado', preco: 180.00 }, { descricao: 'Higienização do ar', preco: 120.00 }, { descricao: 'Troca de compressor AC', preco: 600.00 }, { descricao: 'Troca de condensador', preco: 400.00 }, { descricao: 'Diagnóstico do ar-condicionado', preco: 150.00 },
                { descricao: 'Troca de correia dentada', preco: 450.00 }, { descricao: 'Troca de correia auxiliar', preco: 200.00 }, { descricao: 'Ajuste de válvulas', preco: 380.00 }, { descricao: 'Troca de embreagem', preco: 700.00 }, { descricao: 'Retífica parcial', preco: 1200.00 }, { descricao: 'Retífica completa', preco: 3500.00 }, { descricao: 'Troca de coxins', preco: 250.00 }, { descricao: 'Limpeza de bicos', preco: 220.00 }, { descricao: 'Troca de bomba de combustível', preco: 300.00 }, { descricao: 'Troca de bomba d’água', preco: 280.00 },
                { descricao: 'Check-up pré-viagem', preco: 150.00 }, { descricao: 'Inspeção veicular', preco: 120.00 }, { descricao: 'Ajuste de portas', preco: 100.00 }, { descricao: 'Ajuste de capô', preco: 90.00 }, { descricao: 'Troca de palhetas', preco: 60.00 }, { descricao: 'Troca de escapamento', preco: 300.00 }, { descricao: 'Solda de escapamento', preco: 150.00 }, { descricao: 'Limpeza do motor', preco: 180.00 }, { descricao: 'Polimento técnico', preco: 250.00 }, { descricao: 'Cristalização', preco: 350.00 },
                { descricao: 'Inspeção periódica frota', preco: 120.00 }, { descricao: 'Manutenção preventiva frota', preco: 300.00 }, { descricao: 'Laudo técnico', preco: 200.00 }, { descricao: 'Diagnóstico pré-compra', preco: 250.00 }, { descricao: 'Controle de emissões', preco: 180.00 }, { descricao: 'Ajuste de injeção eletrônica', preco: 300.00 }, { descricao: 'Atualização de software ECU', preco: 350.00 }, { descricao: 'Instalação de acessórios', preco: 150.00 }, { descricao: 'Instalação de alarme', preco: 200.00 }, { descricao: 'Instalação de som', preco: 250.00 },
                { descricao: 'Diagnóstico de falha intermitente', preco: 300.00 }, { descricao: 'Diagnóstico de consumo excessivo', preco: 200.00 }, { descricao: 'Diagnóstico de ruídos', preco: 180.00 }, { descricao: 'Diagnóstico de vibração', preco: 220.00 }, { descricao: 'Teste de compressão', preco: 150.00 }, { descricao: 'Teste de vazamento', preco: 180.00 }, { descricao: 'Análise de gases', preco: 120.00 }, { descricao: 'Diagnóstico de transmissão', preco: 350.00 }, { descricao: 'Diagnóstico elétrico avançado', preco: 400.00 }, { descricao: 'Diagnóstico completo premium', preco: 600.00 },
                { descricao: 'Revisão pós-serviço', preco: 100.00 }, { descricao: 'Reaperto geral', preco: 90.00 }, { descricao: 'Limpeza interna', preco: 150.00 }, { descricao: 'Limpeza externa', preco: 120.00 }, { descricao: 'Revisão de garantia', preco: 130.00 }, { descricao: 'Ajuste eletrônico fino', preco: 180.00 }, { descricao: 'Troca de sensores', preco: 200.00 }, { descricao: 'Teste rodagem', preco: 100.00 }, { descricao: 'Checklist entrega', preco: 80.00 }, { descricao: 'Atendimento emergencial', preco: 300.00 }
            ]
        });
        console.log('Seeding new parts...');
        await prisma.peca.createMany({
            data: [
                { descricao: 'Óleo do motor 5W30', preco: 65.00, quantidade_estoque: 10 }, { descricao: 'Óleo do motor 10W40', preco: 55.00, quantidade_estoque: 10 }, { descricao: 'Filtro de óleo', preco: 35.00, quantidade_estoque: 10 }, { descricao: 'Filtro de ar', preco: 45.00, quantidade_estoque: 10 }, { descricao: 'Filtro de combustível', preco: 60.00, quantidade_estoque: 10 }, { descricao: 'Filtro de cabine', preco: 50.00, quantidade_estoque: 10 }, { descricao: 'Fluido de freio DOT 4', preco: 40.00, quantidade_estoque: 10 }, { descricao: 'Aditivo radiador', preco: 35.00, quantidade_estoque: 10 },
                { descricao: 'Pastilha de freio dianteira', preco: 180.00, quantidade_estoque: 10 }, { descricao: 'Pastilha de freio traseira', preco: 160.00, quantidade_estoque: 10 }, { descricao: 'Disco de freio dianteiro', preco: 220.00, quantidade_estoque: 10 }, { descricao: 'Disco de freio traseiro', preco: 200.00, quantidade_estoque: 10 }, { descricao: 'Lona de freio', preco: 140.00, quantidade_estoque: 10 }, { descricao: 'Cilindro mestre', preco: 320.00, quantidade_estoque: 10 }, { descricao: 'Servo-freio', preco: 450.00, quantidade_estoque: 10 },
                { descricao: 'Amortecedor dianteiro', preco: 350.00, quantidade_estoque: 10 }, { descricao: 'Amortecedor traseiro', preco: 320.00, quantidade_estoque: 10 }, { descricao: 'Mola helicoidal', preco: 280.00, quantidade_estoque: 10 }, { descricao: 'Bandeja de suspensão', preco: 300.00, quantidade_estoque: 10 }, { descricao: 'Pivô de suspensão', preco: 140.00, quantidade_estoque: 10 }, { descricao: 'Terminal de direção', preco: 150.00, quantidade_estoque: 10 }, { descricao: 'Barra estabilizadora', preco: 260.00, quantidade_estoque: 10 }, { descricao: 'Coxim do amortecedor', preco: 120.00, quantidade_estoque: 10 },
                { descricao: 'Bateria 60Ah', preco: 520.00, quantidade_estoque: 10 }, { descricao: 'Alternador', preco: 850.00, quantidade_estoque: 10 }, { descricao: 'Motor de partida', preco: 780.00, quantidade_estoque: 10 }, { descricao: 'Velas de ignição', preco: 160.00, quantidade_estoque: 10 }, { descricao: 'Cabo de vela', preco: 140.00, quantidade_estoque: 10 }, { descricao: 'Sensor de oxigênio', preco: 320.00, quantidade_estoque: 10 }, { descricao: 'Sensor MAP', preco: 280.00, quantidade_estoque: 10 }, { descricao: 'Sensor de rotação', preco: 220.00, quantidade_estoque: 10 }, { descricao: 'Lâmpada farol', preco: 45.00, quantidade_estoque: 10 },
                { descricao: 'Radiador', preco: 650.00, quantidade_estoque: 10 }, { descricao: 'Ventoinha', preco: 380.00, quantidade_estoque: 10 }, { descricao: 'Válvula termostática', preco: 180.00, quantidade_estoque: 10 }, { descricao: 'Bomba d’água', preco: 280.00, quantidade_estoque: 10 }, { descricao: 'Mangueira radiador', preco: 120.00, quantidade_estoque: 10 }, { descricao: 'Compressor de ar-condicionado', preco: 1200.00, quantidade_estoque: 10 }, { descricao: 'Condensador', preco: 520.00, quantidade_estoque: 10 },
                { descricao: 'Correia dentada', preco: 180.00, quantidade_estoque: 10 }, { descricao: 'Correia auxiliar', preco: 120.00, quantidade_estoque: 10 }, { descricao: 'Kit embreagem', preco: 1100.00, quantidade_estoque: 10 }, { descricao: 'Bomba de combustível', preco: 420.00, quantidade_estoque: 10 }, { descricao: 'Injetor de combustível', preco: 380.00, quantidade_estoque: 10 }, { descricao: 'Coxim do motor', preco: 220.00, quantidade_estoque: 10 }, { descricao: 'Junta do cabeçote', preco: 350.00, quantidade_estoque: 10 }, { descricao: 'Retentor de óleo', preco: 90.00, quantidade_estoque: 10 }, { descricao: 'Palheta limpador', preco: 80.00, quantidade_estoque: 10 }, { descricao: 'Escapamento intermediário', preco: 450.00, quantidade_estoque: 10 }, { descricao: 'Silencioso traseiro', preco: 380.00, quantidade_estoque: 10 }
            ]
        });
        console.log('Done populating.');
    } else {
        console.log('Already populated.');
    }
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
