import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable } from '@nestjs/common';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      // O || garante que, se o .env falhar ou atrasar, o sistema use a chave local
      secretOrKey: process.env.JWT_SECRET || 'chave_super_secreta_fleetcare_2026',
    });
  }

  async validate(payload: any) {
    return { id: payload.sub, email: payload.email, perfil: payload.perfil };
  }
}