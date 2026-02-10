import { ExecutionContext, Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
    canActivate(context: ExecutionContext) {
        // DEV: Bypass Auth & Mock User
        const request = context.switchToHttp().getRequest();
        request.user = {
            userId: 'dev-user-id',
            email: 'manager@acme.com',
            role: 'MANAGER',
            organizationId: 'dev-org-id', // Added organizationId
        };
        return true;
    }
}
