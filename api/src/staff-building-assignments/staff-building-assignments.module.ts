import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { StaffBuildingAssignmentsController } from './staff-building-assignments.controller';
import { StaffBuildingAssignmentsService } from './staff-building-assignments.service';

@Module({
  imports: [AuthModule],
  controllers: [StaffBuildingAssignmentsController],
  providers: [StaffBuildingAssignmentsService],
})
export class StaffBuildingAssignmentsModule {}
