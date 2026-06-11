import { Request, Response } from "express";
import {
  createOrderSchema,
  updateOrderFinancialSchema,
  updateOrderStatusSchema
} from "./orders.schema";
import * as ordersService from "./orders.service";

export async function createOrder(request: Request, response: Response) {
  const body = createOrderSchema.parse(request.body);

  const order = await ordersService.createOrder({
    ownerId: request.user!.id,
    role: request.user!.role,
    ...body
  });

  return response.status(201).json(order);
}

export async function listOrders(request: Request, response: Response) {
  const orders = await ordersService.listOrders(request.user!.id, request.user!.role);
  return response.json(orders);
}

export async function getOrderById(request: Request, response: Response) {
  const orderId = getOrderId(request);
  const order = await ordersService.getOrderById(
    orderId,
    request.user!.id,
    request.user!.role
  );

  return response.json(order);
}

export async function updateOrderStatus(request: Request, response: Response) {
  const body = updateOrderStatusSchema.parse(request.body);
  const orderId = getOrderId(request);
  const order = await ordersService.updateOrderStatus(
    orderId,
    body.status,
    body.refusalReason,
    request.user!.id,
    request.user!.role
  );

  return response.json(order);
}

export async function updateOrderFinancial(request: Request, response: Response) {
  const body = updateOrderFinancialSchema.parse(request.body);
  const orderId = getOrderId(request);
  const order = await ordersService.updateOrderFinancial(
    orderId,
    body.materialCost,
    request.user!.id,
    request.user!.role
  );

  return response.json(order);
}

function getOrderId(request: Request) {
  const { id } = request.params;
  return Array.isArray(id) ? id[0] : id;
}
