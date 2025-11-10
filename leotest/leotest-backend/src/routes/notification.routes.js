// leotest-backend/src/routes/notification.routes.js

import express from "express";
import { getNotifications, markAsRead } from "../controllers/notification.controller.js";

const router = express.Router();

router.get("/:userId", getNotifications);
router.put("/read/:id_notificacion", markAsRead);

export default router;