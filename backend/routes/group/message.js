import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkGroupPermission } from '../middleware.js'

const router = express.Router();

export default router