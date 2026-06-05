import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkAdmin } from '../middleware.js'

const router = express.Router()
