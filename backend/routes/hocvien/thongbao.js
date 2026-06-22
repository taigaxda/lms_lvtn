import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkHocVien } from '../middleware.js'

const router = express.Router()
