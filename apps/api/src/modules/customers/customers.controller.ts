import { Request, Response } from "express";
import {
  createCustomerSchema,
  updateCustomerStatusSchema
} from "./customers.schema";
import * as customersService from "./customers.service";

export async function listCustomers(request: Request, response: Response) {
  const customers = await customersService.listCustomers(request.user!.id);
  return response.json(customers);
}

export async function createCustomer(request: Request, response: Response) {
  const body = createCustomerSchema.parse(request.body);
  const customer = await customersService.createCustomer(request.user!.id, body);
  return response.status(201).json(customer);
}

export async function deleteCustomer(request: Request, response: Response) {
  const result = await customersService.deleteCustomer(
    request.user!.id,
    getCustomerId(request)
  );

  return response.json(result);
}

export async function updateCustomerStatus(request: Request, response: Response) {
  const body = updateCustomerStatusSchema.parse(request.body);
  const customer = await customersService.updateCustomerStatus(
    request.user!.id,
    getCustomerId(request),
    body.status
  );

  return response.json(customer);
}

function getCustomerId(request: Request) {
  const { id } = request.params;
  return Array.isArray(id) ? id[0] : id;
}
