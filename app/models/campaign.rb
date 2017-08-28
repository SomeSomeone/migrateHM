class Campaign < ApplicationRecord

	def actual?
		((self.number||0)>0||self.inf_number)&&(self.period>Time.now||self.inf_period)
	end

	def get_one
		if (!self.inf_number || (self.number||0) > 0)
			self.number-=1
			self.save
		end
	end
end