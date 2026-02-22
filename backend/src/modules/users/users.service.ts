import { Injectable, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../prisma/prisma.service';
import { ListUsersDto } from './dto/list-users.dto';
import { CreateUserDto } from './dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findAll(organizationId: string, query: ListUsersDto) {
    const { search, department, page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const where: any = {
      organizationId,
      isActive: true,
    };

    if (search) {
      where.OR = [
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (department) {
      where.department = department;
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          phone: true,
          avatarUrl: true,
          role: true,
          department: true,
          designation: true,
        },
        orderBy: { firstName: 'asc' },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      users,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findById(id: string, organizationId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id, organizationId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        avatarUrl: true,
        role: true,
        department: true,
        designation: true,
        manager: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
          },
        },
        createdAt: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async getTeam(userId: string, organizationId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, organizationId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const reports = await this.prisma.user.findMany({
      where: {
        managerId: userId,
        isActive: true,
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        avatarUrl: true,
        department: true,
        designation: true,
      },
      orderBy: { firstName: 'asc' },
    });

    return { reports };
  }

  async create(data: CreateUserDto) {
    const passwordHash = await bcrypt.hash(data.password, 10);

    return this.prisma.user.create({
      data: {
        email: data.email,
        passwordHash,
        firstName: data.firstName,
        lastName: data.lastName,
        phone: data.phone,
        role: data.role,
        organizationId: data.organizationId,
        managerId: data.managerId,
        department: data.department,
        designation: data.designation,
        facePhoto: data.facePhoto,
      },
    });
  }

  async getAllFacePhotos(organizationId: string) {
    const users = await this.prisma.user.findMany({
      where: {
        organizationId,
        isActive: true,
        facePhoto: { not: null },
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        facePhoto: true,
      },
    });

    return {
      employees: users.map((u) => ({
        id: u.id,
        name: `${u.firstName} ${u.lastName}`,
        facePhoto: u.facePhoto,
      })),
    };
  }

  async getFacePhoto(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { facePhoto: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return { facePhoto: user.facePhoto };
  }

  async updateAvatar(userId: string, filename: string) {
    const avatarUrl = `/uploads/avatars/${filename}`;
    await this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl },
    });
    return { avatarUrl };
  }

  async findByEmail(email: string) {
    return this.prisma.user.findUnique({
      where: { email },
    });
  }
}
