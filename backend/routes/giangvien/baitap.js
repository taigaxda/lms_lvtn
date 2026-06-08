import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkGiangVien } from '../middleware.js'

const router = express.Router();

export default router