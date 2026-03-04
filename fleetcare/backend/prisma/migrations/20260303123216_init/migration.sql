/*
  Warnings:

  - The primary key for the `Cliente` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `cpf_cnpj` on the `Cliente` table. All the data in the column will be lost.
  - You are about to drop the column `totalGasto` on the `Cliente` table. All the data in the column will be lost.
  - The `id` column on the `Cliente` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The primary key for the `OrdemServico` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `cliente_id` on the `OrdemServico` table. All the data in the column will be lost.
  - You are about to drop the column `data_abertura` on the `OrdemServico` table. All the data in the column will be lost.
  - You are about to drop the column `data_fechamento` on the `OrdemServico` table. All the data in the column will be lost.
  - You are about to drop the column `descontoAplicado` on the `OrdemServico` table. All the data in the column will be lost.
  - You are about to drop the column `numero` on the `OrdemServico` table. All the data in the column will be lost.
  - You are about to drop the column `valorFinal` on the `OrdemServico` table. All the data in the column will be lost.
  - You are about to drop the column `valorMaoDeObra` on the `OrdemServico` table. All the data in the column will be lost.
  - You are about to drop the column `valor_total` on the `OrdemServico` table. All the data in the column will be lost.
  - The `id` column on the `OrdemServico` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The primary key for the `Usuario` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The `id` column on the `Usuario` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The primary key for the `Veiculo` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The `id` column on the `Veiculo` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - You are about to drop the `ItemPecaOS` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `ItemServicoOS` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Pagamento` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Peca` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Servico` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `cliente_nome` to the `OrdemServico` table without a default value. This is not possible if the table is not empty.
  - Added the required column `descricao` to the `OrdemServico` table without a default value. This is not possible if the table is not empty.
  - Added the required column `veiculo_placa` to the `OrdemServico` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `veiculo_id` on the `OrdemServico` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `perfil` on the `Usuario` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Added the required column `cliente_nome` to the `Veiculo` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `cliente_id` on the `Veiculo` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- DropForeignKey
ALTER TABLE "ItemPecaOS" DROP CONSTRAINT "ItemPecaOS_ordem_servico_id_fkey";

-- DropForeignKey
ALTER TABLE "ItemPecaOS" DROP CONSTRAINT "ItemPecaOS_peca_id_fkey";

-- DropForeignKey
ALTER TABLE "ItemServicoOS" DROP CONSTRAINT "ItemServicoOS_ordem_servico_id_fkey";

-- DropForeignKey
ALTER TABLE "ItemServicoOS" DROP CONSTRAINT "ItemServicoOS_servico_id_fkey";

-- DropForeignKey
ALTER TABLE "OrdemServico" DROP CONSTRAINT "OrdemServico_cliente_id_fkey";

-- DropForeignKey
ALTER TABLE "OrdemServico" DROP CONSTRAINT "OrdemServico_veiculo_id_fkey";

-- DropForeignKey
ALTER TABLE "Pagamento" DROP CONSTRAINT "Pagamento_ordem_servico_id_fkey";

-- DropForeignKey
ALTER TABLE "Veiculo" DROP CONSTRAINT "Veiculo_cliente_id_fkey";

-- DropIndex
DROP INDEX "Cliente_cpf_cnpj_key";

-- DropIndex
DROP INDEX "Cliente_email_key";

-- DropIndex
DROP INDEX "OrdemServico_numero_key";

-- AlterTable
ALTER TABLE "Cliente" DROP CONSTRAINT "Cliente_pkey",
DROP COLUMN "cpf_cnpj",
DROP COLUMN "totalGasto",
ADD COLUMN     "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "documento" TEXT,
ADD COLUMN     "tipo" TEXT,
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
ALTER COLUMN "telefone" DROP NOT NULL,
ALTER COLUMN "email" DROP NOT NULL,
ADD CONSTRAINT "Cliente_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "OrdemServico" DROP CONSTRAINT "OrdemServico_pkey",
DROP COLUMN "cliente_id",
DROP COLUMN "data_abertura",
DROP COLUMN "data_fechamento",
DROP COLUMN "descontoAplicado",
DROP COLUMN "numero",
DROP COLUMN "valorFinal",
DROP COLUMN "valorMaoDeObra",
DROP COLUMN "valor_total",
ADD COLUMN     "cliente_nome" TEXT NOT NULL,
ADD COLUMN     "criadoEm" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "descricao" TEXT NOT NULL,
ADD COLUMN     "veiculo_placa" TEXT NOT NULL,
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
ALTER COLUMN "status" SET DEFAULT 'ABERTA',
DROP COLUMN "veiculo_id",
ADD COLUMN     "veiculo_id" INTEGER NOT NULL,
ADD CONSTRAINT "OrdemServico_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "Usuario" DROP CONSTRAINT "Usuario_pkey",
ADD COLUMN     "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "status" TEXT NOT NULL DEFAULT 'Ativo',
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
DROP COLUMN "perfil",
ADD COLUMN     "perfil" TEXT NOT NULL,
ADD CONSTRAINT "Usuario_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "Veiculo" DROP CONSTRAINT "Veiculo_pkey",
ADD COLUMN     "cliente_nome" TEXT NOT NULL,
ADD COLUMN     "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
DROP COLUMN "cliente_id",
ADD COLUMN     "cliente_id" INTEGER NOT NULL,
ADD CONSTRAINT "Veiculo_pkey" PRIMARY KEY ("id");

-- DropTable
DROP TABLE "ItemPecaOS";

-- DropTable
DROP TABLE "ItemServicoOS";

-- DropTable
DROP TABLE "Pagamento";

-- DropTable
DROP TABLE "Peca";

-- DropTable
DROP TABLE "Servico";

-- DropEnum
DROP TYPE "Perfil";

-- AddForeignKey
ALTER TABLE "Veiculo" ADD CONSTRAINT "Veiculo_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "Cliente"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrdemServico" ADD CONSTRAINT "OrdemServico_veiculo_id_fkey" FOREIGN KEY ("veiculo_id") REFERENCES "Veiculo"("id") ON DELETE CASCADE ON UPDATE CASCADE;
